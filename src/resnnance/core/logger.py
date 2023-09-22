import logging

def resnnance_logger(name=None):
    if name == None:
        logger_name = "resnnance"
    else:
        logger_name = "resnnance." + name

    # Create logger
    logger = logging.getLogger(f"{logger_name}")
    logger.setLevel(logging.INFO)

    # Create handler for father logger
    if name == None:
        # Create log handler (for console output)
        handler = logging.StreamHandler()
        handler.setLevel(logging.INFO)

        # Format log output
        formatter = logging.Formatter( '%(asctime)s - %(name)s - %(levelname)s: %(message)s', "%Y-%m-%d %H:%M:%S")
        handler.setFormatter(formatter)
        logger.addHandler(handler)

    return logger