import jinja2
import logging


class ReSNNance(object):

    def __init__(self):
        # Create templating environment
        self.env = jinja2.Environment(loader=jinja2.PackageLoader("resnnance.core"))

        # Create log
        self.logger = logging.getLogger("resnnance.core")
        self.logger.setLevel(logging.INFO)

        # Create log handler (for console output)
        handler = logging.StreamHandler()
        handler.setLevel(logging.INFO)

        # Format log output
        formatter = logging.Formatter( '%(asctime)s - %(name)s - %(levelname)s: %(message)s')
        handler.setFormatter(formatter)
        self.logger.addHandler(handler)

        # Log ReSNNance core creation
        self.logger.info("Created new ReSNNance core")


    def create_snap(self, num):
        # Create template from string
        template = self.env.get_template("template.vhd")

        # Render template
        for i in range(num):
            # Set template parameters and render content
            params = {'entity_name': f"snap_{i}", 'arch_name': 'arch'}
            content = template.render(**params)

            # Write to files
            filename = f"snap_{i}.vhd"
            with open(filename, mode="w", encoding="utf-8") as message:
                message.write(content)
                self.logger.info(f"Wrote {filename}")


