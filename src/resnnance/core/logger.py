import logging

def resnnance_logger(logger_name):
    # Create logger
    logger = logging.getLogger(f"{logger_name}")
    logger.setLevel(logging.INFO)

    # Create log handler (for console output)
    handler = logging.StreamHandler()
    handler.setLevel(logging.INFO)

    # Format log output
    formatter = logging.Formatter( '%(asctime)s - %(name)s - %(levelname)s: %(message)s')
    handler.setFormatter(formatter)
    logger.addHandler(handler)

    return logger