from __future__ import print_function
from tempfile import mkstemp, gettempdir
from typing import Any, Dict
import hashlib
import logging
import json
import requests
import subprocess
import sys


logger = logging.getLogger(__name__)

try:
    subprocess.check_output('ffmpeg -version', shell=True)
except subprocess.CalledProcessError:
    print('error: ffmpeg not found', file=sys.stderr)
    exit(1)


def ffprobe_get_info(path: str) -> Dict[str, Any]:
    cmd = 'ffprobe -v error -of json -show_entries stream=width,height,duration {}'.format(path)
    out = subprocess.check_output(cmd, shell=True)
    return json.loads(out)


def ffmpeg_generate_thumb(path: str, suffix: str = '.jpg') -> str:
    """Generate thumbnail from given path using ffmpeg. Returns path to generated file"""
    info = ffprobe_get_info(path)
    width = info['streams'][0]['width']
    height = info['streams'][0]['height']

    scale = '-1:90'
    if width < height:
        side = min(320, height)
        scale = '-1:{}'.format(side)
    else:
        side = min(320, width)
        scale = '{}:-1'.format(side)

    _, filename = mkstemp(suffix=suffix)
    cmd = 'ffmpeg -v error -i "{}" -ss 00:00:01.000 -vframes 1 -filter:v scale="{}" -y {}'.format(path, scale, filename)
    subprocess.check_output(cmd, shell=True)
    return filename


def ffmpeg_concat(audio: str, video: str, suffix: str = '.mp4') -> str:
    """Concatinate audio and video stream. Reutns result file path"""
    _, filename = mkstemp(suffix=suffix)
    cmd = 'ffmpeg -v error -y -i {} -i {} {}'.format(video, audio, filename)
    logger.debug(cmd)
    subprocess.check_output(cmd, shell=True)
    return filename


def ffmpeg_join(videos: [str], suffix: str = '.mp4') -> str:
    """Concatinate multiple videos into one. Reutns result file path"""
    _, txtfile = mkstemp(suffix='.txt')
    _, mp4file = mkstemp(suffix=suffix)
    lines = list(map(lambda v: f'file {v}\n', videos))
    open(txtfile, 'w').writelines(lines)
    cmd = 'ffmpeg -v error -y -f concat -safe 0 -i {} -c copy {}'.format(txtfile, mp4file)
    logger.debug(cmd)
    subprocess.check_output(cmd, shell=True)
    return mp4file


def download(url: str, suffix: str = '.mp4', cache: str = False) -> str:
    """Download file via given url. Returns path to downloaded file"""
    if cache:
        hasher = hashlib.md5()
        hasher.update(cache.encode('utf-8'))
        filename = f'{gettempdir()}/{hasher.hexdigest()}{suffix}'
    else:
        _, filename = mkstemp(suffix=suffix)

    logger.debug(f'Downloading {url} to {filename}')

    r = requests.get(url, stream=True)
    expected_size = int(r.headers['content-length'])
    download_size = 0
    with open(filename, 'wb') as f:
        for chunk in r.iter_content(chunk_size=1000000):
            # for chunk in r.iter_lines():
            download_size += len(chunk)
            print('downloaded {:.0f} MB of {:.0f} MB ({:.01f}%)'.format(download_size / 1024 / 1024, expected_size / 1024 / 1024, download_size * 100 / expected_size), end='\r')
            f.write(chunk)

    logger.debug('File downloaded {}'.format(filename))
    return filename
