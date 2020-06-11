import logging
import time
from telegram.client import Telegram


class TgClient(object):

    logger = logging.getLogger(__name__)

    def __init__(self, phone: str, files_directory: str = None) -> None:
        assert phone.startswith('+'), f'the phone number must have a "+" prefix, had {phone}'
        self.logger.debug(f'Login as {phone}')

        self.tg = Telegram(
            api_id='94575',
            api_hash='a3406de8d171bb422bb6ddf3bbd800e2',
            phone=phone,
            files_directory=files_directory,
            database_encryption_key='dfaafaad2972d7636bf277ab',
        )

        self.results = {}
        self.tg.add_update_handler('updateFile', self._update_file_handler)
        self.tg.add_update_handler('updateMessageSendSucceeded', self._update_message_send_succeeded_handler)
        self.tg.login()

    def _update_file_handler(self, update):
        expected_size = update["file"]["expected_size"]
        uploaded_size = update["file"]["remote"]["uploaded_size"]

        if not expected_size:
            return

        print('uploaded {:.0f} MB of {:.0f} MB ({:.01f}%)'.format(uploaded_size / 1024 / 1024, expected_size / 1024 / 1024, uploaded_size * 100 / expected_size), end='\r')

    def _update_message_send_succeeded_handler(self, update):
        self.logger.debug('Message {} sent successfully. New message id {}'.format(update['old_message_id'], update['message']['id']))
        self.results[update['old_message_id']] = update

    def upload_video(
            self,
            path: str,
            chat_id: int,
            thumb_path: str = None,
            thumb_width: int = 0,
            thumb_height: int = 0,
            duration: int = 0,
            width: int = 0,
            height: int = 0,
            caption: str = None,
            supports_streaming: bool = False,
    ) -> str:
        args = list(map(lambda t: f'{t[0]}: {t[1]}', locals().items()))

        self.logger.debug('Updating chat list')
        result = self.tg.get_chats()
        result.wait()

        self.logger.debug('Sending {}'.format(', '.join(args[1:])))

        content = {
            '@type': 'inputMessageVideo',
            'video': {
                '@type': 'inputFileLocal',
                'path': path,
            },
            'duration': duration,
            'width': width,
            'height': height,
            'supports_streaming': supports_streaming,
        }

        if thumb_path:
            content['thumbnail'] = {
                '@type': 'inputThumbnail',
                'thumbnail': {
                    '@type': 'inputFileLocal',
                    'path': thumb_path,
                },
                'width': thumb_width,
                'height': thumb_height,
            }

        if caption:
            content['caption'] = {
                '@type': 'formattedText',
                'text': caption,
            }

        data = {
            '@type': 'sendMessage',
            'chat_id': chat_id,
            'input_message_content': content,
        }

        result = self.tg._send_data(data)
        result.wait()

        if result.error:
            self.logger.error(f'ok_received: {result.ok_received}, error_info: {result.error_info}, update: {result.update}')

        message_id = result.update['id']
        self.logger.debug(f'Awaiting message {message_id} to be sent')

        while message_id not in self.results:
            time.sleep(0.1)

        return self.results[message_id]['message']['content']['video']['video']['remote']['id']
