import json
import logging
import requests
from typing import Any, Dict


class IgClient(object):

    logger = logging.getLogger(__name__)

    def __init__(self, cookies: Dict[str, Any] = {}) -> None:
        self._cookies = {
            'sessionid': None,
            'ds_user_id': None,
            'csrftoken': None,
            'shbid': None,
            'rur': None,
            'mid': None,
            'shbts': None,
        }
        self._cookies.update(cookies)
        self._headers = {
            'accept-langauge': 'en-US;q=0.9,en;q=0.8,es;q=0.7',
            'origin': 'https://www.instagram.com',
            'referer': 'https://www.instagram.com/',
            'upgrade-insecure-requests': '1',
            'user-agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/68.0.3440.106 Safari/537.36',
        }

    def get_profile_by_username(self, username: str) -> Dict[str, Any]:
        self.logger.debug(f'Getting profile for {username}')
        assert isinstance(username, str), 'username must be a string'
        headers = self._headers
        headers.update({
            'referer': 'https://www.instagram.com/{}/'.format(username),
        })
        res = requests.get(
            'https://www.instagram.com/{}/?__a=1'.format(username),
            headers=headers,
            cookies=self._cookies
        )
        try:
            return res.json()['graphql']['user']
        except:  # noqa: E722
            print(res.text)
            raise

    def get_story_reels_by_username(self, username: str) -> Dict[str, Any]:
        self.logger.debug(f'Getting story reels for {username}')
        profile = self.get_profile_by_username(username)
        params = {
            'query_hash': 'ba71ba2fcb5655e7e2f37b05aec0ff98',
            'variables': json.dumps({
                'reel_ids': [profile['id']],
                'tag_names': [],
                'location_ids': [],
                'precomposed_overlay': False
            })
        }
        res = requests.get(
            'https://www.instagram.com/graphql/query/',
            params=params,
            cookies=self._cookies
        )
        open('get_story_reels_by_username_{}.json'.format(username), 'w').write(json.dumps(res.json(), indent=4, sort_keys=True, ensure_ascii=False))
        return res.json()['data']['reels_media']

    def get_channel_by_username(self, username: str) -> Dict[str, Any]:
        self.logger.debug(f'Getting channel for {username}')
        assert isinstance(username, str), 'username must be a string'
        headers = self._headers
        headers.update({
            'referer': 'https://www.instagram.com/{}/'.format(username),
        })
        res = requests.get(
            'https://www.instagram.com/{}/channel/?__a=1'.format(username),
            headers=headers,
            cookies=self._cookies
        )
        # open('get_channel_by_username_{}.json'.format(username), 'w').write(json.dumps(res.json(), indent=4, sort_keys=True, ensure_ascii=False))
        return res.json()['graphql']['user']

    def get_tv(self, code: str) -> Dict[str, Any]:
        self.logger.debug(f'Getting tv by shortcode: {code}')
        headers = self._headers
        headers.update({
            'referer': 'https://www.instagram.com/tv/{}/'.format(code),
        })
        res = requests.get(
            'https://www.instagram.com/tv/{}/?__a=1'.format(code),
            headers=headers,
            # cookies=self._cookies
        )
        # open('get_tv_{}.json'.format(code), 'w').write(json.dumps(res.json(), indent=4, sort_keys=True, ensure_ascii=False))
        return res.json()['graphql']['shortcode_media']

    def get_broadcasts_by_username(self, username: str) -> Dict[str, Any]:
        self.logger.debug(f'Getting broadcasts for {username}')
        profile = self.get_profile_by_username(username)
        headers = self._headers
        headers.update({
            'user-agent': 'Instagram 10.26.0 (iPhone7,2; iOS 10_1_1; en_US; en-US; scale=2.00; gamut=normal; 750x1334) AppleWebKit/420+',
        })
        res = requests.get(
            'https://i.instagram.com/api/v1/feed/user/{}/story/'.format(profile['id']),
            headers=headers,
            cookies=self._cookies
        )
        return res.json()
