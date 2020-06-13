import logging
import requests
import time
from abc import abstractmethod
from .config import DATA_DIR
from decouple import config
from functools import wraps
from os import path
from typing import Any, Dict, Callable

from .helpers import download, ffprobe_get_info, ffmpeg_generate_thumb
from .tgclient import TgClient


def _retry_on_error(func: Callable) -> Callable:
    """ Decorator to repeat request if error oссured """
    @wraps(func)
    def call(cls, *args, **kwargs):
        rv = func(cls, *args, **kwargs)
        retry = 5
        while not rv['ok'] and retry:
            if cls.logger:
                cls.logger.error(f'{func.__name__} failed: {rv}, {args}, {kwargs}, retry: {retry}')
            time.sleep(5)
            retry -= 1
            rv = func(cls, *args, **kwargs)

        return rv
    return call


class Media(object):
    def __init__(self, url: str, caption: str = None, shortcode: str = None):
        self.url = url
        self.caption = caption
        self.shortcode = shortcode

    def __repr__(self):
        return '{{"url": "{}", "caption": "{}", "shortcode": "{}"}}'.format(self.url, self.caption, self.shortcode)


class PublishStrategy(object):

    logger = logging.getLogger(f'{__package__}.pb_strtg' if __package__ else 'pb_strtg')

    def __init__(self, chat_id: Any):
        self.chat_id = chat_id
        self._items = []

    def add(self, item: Media) -> None:
        self._items.append(item)

    @abstractmethod
    def publish(self):
        """ Method should me overriden in subclass """


class PublishStrategyVideo(PublishStrategy):

    def __init__(self, reserve_chat_id: Any = None, **kwargs):
        super().__init__(kwargs['chat_id'])
        if not reserve_chat_id:
            self.logger.warning(f'reserve_chat_id not set. Using {self.chat_id} as reserve')
            reserve_chat_id = self.chat_id
        self._upload_strategy = UploadStrategy(reserve_chat_id)

    def publish(self) -> Dict[str, Any]:
        if not self._items:
            self.logger.warning('Nothing to publish')
            return {}

        for m in self._items:
            file_id = self._upload_strategy.publish(m.url, m.shortcode)
            rv = self.send_video(self.chat_id, file_id, m.caption)

            if not rv['ok']:
                self.logger.error(f'{rv}, {m}')

        self._items = []
        return rv

    @_retry_on_error
    def send_video(self, chat_id: int, file_id: str, caption: str = None) -> Dict[str, Any]:
        url = 'https://api.telegram.org/bot{}/sendVideo'.format(config('TG_BOT_TOKEN'))
        payload = {
            'chat_id': chat_id,
            'video': file_id,
        }

        if caption:
            payload['caption'] = caption

        r = requests.post(url, json=payload)
        return r.json()


class PublishStrategyAlbum(PublishStrategy):

    def __init__(self, **kwargs):
        super().__init__(kwargs['chat_id'])

    def publish(self) -> Dict[str, Any]:
        if not self._items:
            self.logger.warning('Nothing to publish')
            return {}

        self.logger.debug(f'Publishing {len(self._items)} element(s)')

        while self._items:
            media = self._items[:10]
            rv = self.send_media_group(self.chat_id, media)

            if not rv['ok']:
                self.logger.error(f'{rv}, {media}')

            del self._items[:10]
            self.logger.debug(f'{len(media)} published, {len(self._items)} awaiting')

        return rv

    @_retry_on_error
    def send_media_group(self, chat_id: int, items: [Media]) -> Dict[str, Any]:
        assert len(items), 'Attempt to send empty media group'
        media = []
        for i in items:
            media.append({
                'media': i.url,
                'type': 'video' if '.mp4' in i.url else 'photo',
                'caption': i.caption,
            })

        url = 'https://api.telegram.org/bot{}/sendMediaGroup'.format(config('TG_BOT_TOKEN'))
        payload = {
            'chat_id': chat_id,
            'media': media,
        }
        r = requests.post(url, json=payload)
        res = r.json()

        if not res['ok'] and res['error_code'] == 429:  # Too Many Requests
            time.sleep(res['parameters']['retry_after'])
            return self.send_media_group(chat_id, items)

        return res


class UploadStrategy(PublishStrategy):

    __tg = None

    @property
    def tg(self) -> TgClient:
        if not UploadStrategy.__tg:
            UploadStrategy.__tg = TgClient(config('TG_PHONE'), files_directory=path.join(DATA_DIR, '.tdlib_files'))
        return UploadStrategy.__tg

    def publish(self, url: str, cache: str = None):
        video_path = download(url, cache=cache)
        thumb_path = ffmpeg_generate_thumb(video_path)

        video_info = ffprobe_get_info(video_path)
        thumb_info = ffprobe_get_info(thumb_path)

        file_id = self.tg.upload_video(
            video_path,
            self.chat_id,
            width=video_info['streams'][0]['width'],
            height=video_info['streams'][0]['height'],
            duration=int(float(video_info['streams'][0]['duration'])),
            thumb_path=thumb_path,
            thumb_width=thumb_info['streams'][0]['width'],
            thumb_height=thumb_info['streams'][0]['height'],
            supports_streaming=True,
        )
        self.logger.debug(f'🔥 {file_id}')
        return file_id
