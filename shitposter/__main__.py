import logging
from datetime import datetime
from tinydb import TinyDB
from os import path

from .config import DATA_DIR
from .job import StoryJob, IgtvJob  # noqa: F401

filename = 'log_{}.log'.format(datetime.today().strftime('%Y%m%d_%H%M%S'))
logging.basicConfig(format='%(asctime)s - %(name)8s - %(levelname)7s - %(message)s', level=logging.DEBUG)
logging.getLogger('urllib3').setLevel(logging.WARNING)
logging.getLogger('telegram').setLevel(logging.WARNING)


def main():
    db = TinyDB(path.join(DATA_DIR, 'jobs.json'))
    jobs = db.all()

    if not jobs:
        print('No jobs found')
        exit(0)

    for job in jobs:
        cls = globals()[job['__class']]
        j = cls(**job)
        j.execute()

        if j.ts > job['ts']:
            db.update({'ts': j.ts}, doc_ids=[job.doc_id])


if __name__ == '__main__':
    main()
