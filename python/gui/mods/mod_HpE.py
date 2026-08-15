# -*- coding: utf-8 -*-
from HpE import initialize, finalize
from HpE.logger import logger

__version__ = '0.1.0'
__author__ = 'Dictor1488'
__mod_name__ = 'HpE'


def init():
    try:
        logger.info('loading HpE v%s', __version__)
        initialize()
        logger.info('HpE loaded')
    except Exception:
        logger.exception('HpE initialization failed')


def fini():
    try:
        finalize()
        logger.info('HpE unloaded')
    except Exception:
        logger.exception('HpE finalization failed')
