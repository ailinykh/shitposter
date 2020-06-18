#!/usr/bin/env python
#
# A library that transmits all your instagram stories into telegram channel / chat
# Copyright (C) 2020
# Anton Ilinykh <me@ailinykh.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser Public License for more details.
#
# You should have received a copy of the GNU Lesser Public License
# along with this program.  If not, see [http://www.gnu.org/licenses/].

import logging
from abc import abstractmethod
from .config import DATA_DIR
from datetime import datetime
from tinydb import TinyDB
from typing import Any, Dict
from os import path

from .igclient import IgClient
from .publish_strategy import Media, PublishStrategyAlbum, PublishStrategyVideo


def load_cookies() -> Dict[str, Any]:
    db = TinyDB(path.join(DATA_DIR, 'cookies.json'))
    return db.all()[0] or {}


class Job(object):
    """ This is a base class for all Jobs """

    logger = logging.getLogger(__name__)

    def __init__(self, username: str) -> None:
        self.username = username
        self.ig = IgClient(load_cookies())

    @abstractmethod
    def execute(self):
        """ Method should me overriden in subclass """


class StoryJob(Job):

    def __init__(self,
                 chat_id: Any,
                 reserve_chat_id: Any = None,
                 ts: int = 0,
                 **kwargs):
        super().__init__(kwargs['username'])
        self.ts = ts
        self._publish_strategy = PublishStrategyAlbum(chat_id=chat_id, reserve_chat_id=reserve_chat_id)

    def execute(self):
        data = self.ig.get_story_reels_by_username(self.username)

        if not data:
            self.logger.info(f'No stories for {self.username}')
            return

        stories = data[0]['items']
        ts = 0

        for story in stories:
            if story['taken_at_timestamp'] > self.ts:
                ts = story['taken_at_timestamp']
                caption_pieces = []

                if story['story_cta_url']:
                    caption_pieces.append(story['story_cta_url'])

                for o in story['tappable_objects']:
                    if o['__typename'] == 'GraphTappableMention':
                        caption_pieces.append('{} instagr.am/{}'.format(o['full_name'], o['username']))

                caption = '\n'.join(caption_pieces)
                url = story['video_resources'].pop()['src'] if story['is_video'] else story['display_url']
                video_duration = story['video_duration'] if 'video_duration' in story else 0
                self._publish_strategy.add(Media(url, story['is_video'], video_duration, caption, story['id'], story['taken_at_timestamp']))

        count = len(self._publish_strategy._items)
        if count:
            self._publish_strategy.publish()
            self.ts = ts
            self.logger.info(f'Success for {self.username}, stories posted: {count}, ts: {ts}')
        else:
            self.logger.info(f'No actual stories for {self.username}, ts: {self.ts}')


class IgtvJob(Job):

    def __init__(self,
                 chat_id: Any,
                 reserve_chat_id: Any = None,
                 tag: str = None,
                 ts: int = 0,
                 **kwargs):
        super().__init__(kwargs['username'])
        self.tag = tag
        self.ts = ts
        self._publish_strategy = PublishStrategyVideo(chat_id=chat_id, reserve_chat_id=reserve_chat_id)

    def execute(self):
        data = self.ig.get_channel_by_username(self.username)
        igtv = data['edge_felix_video_timeline']['edges']
        igtv.reverse()
        ts = 0
        for item in igtv:
            t = datetime.fromtimestamp(item['node']['taken_at_timestamp'])
            if (datetime.today() - t).days < 1 and t.timestamp() > self.ts:
                self.logger.info('New live video found {} {}'.format(t.strftime('%c'), item['node']['title']))

                ts = item['node']['taken_at_timestamp']
                tv = self.ig.get_tv(item['node']['shortcode'])

                if self.tag:
                    caption = '{}\n{}'.format(self.tag, item['node']['title'])
                else:
                    caption = item['node']['title']

                self._publish_strategy.add(Media(tv['video_url'], True, 0, caption, item['node']['shortcode']))

        count = len(self._publish_strategy._items)
        if count:
            self.ts = ts
            self._publish_strategy.publish()
            self.logger.info(f'IGTV for {self.username} sucessfully sent! ts: {self.ts}, count: {count}')
        else:
            self.logger.info(f'No actual IGTV for {self.username} ts: {self.ts}')
