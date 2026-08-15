# -*- coding: utf-8 -*-
from .logger import logger
from .player_panel import initialize_panel, finalize_panel
from .provider import install_hooks, remove_hooks
from .settings import g_settings

_initialized = False


def initialize():
    global _initialized
    if _initialized:
        return
    initialize_panel()
    g_settings.initialize()
    install_hooks()
    _initialized = True
    logger.info('HpE initialized')


def finalize():
    global _initialized
    if not _initialized:
        return
    remove_hooks()
    g_settings.finalize()
    finalize_panel()
    _initialized = False
    logger.info('HpE finalized')
