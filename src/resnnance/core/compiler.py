from .logger import resnnance_logger

import os
import jinja2
import numpy as np

class Compiler(object):

    def __init__(self, build_path=None):
        # Log
        self.logger = resnnance_logger("compiler")

        # Create templating environment
        self.env = jinja2.Environment(loader=jinja2.PackageLoader("resnnance.core", "templates"))

        # Set default build path
        if build_path is None:
            self.build_path = ""
        else:
            self.build_path = build_path

    def compile(self, model, path=None):
        self.logger.info("Compiling Resnnance model...")

        # Set build path
        if not path is None:
            self.build_path = path

        # Set up directory tree
        if not os.path.exists(os.path.join(self.build_path, "snaps")):
            os.makedirs(os.path.join(self.build_path, "snaps"))

        # Compile model
        #   One snap per layer
        #   One network wrapper
        #   One network controller
        #   One engine (RISC-V peripheral)

        # Compile layers
        for layer in model.layers:
            # Get layer parameters and render layer (snap) file
            params = layer.get_template_params()
            self.__render_template(layer.template, params, f"{layer.label}.vhd", "snaps")
            
        # Connect layers and render network file
        params = {'layers': [layer.label for layer in model.layers]}
        self.__render_template("hw/network.vhd", params, "network.vhd")

        # Render controller file
        params = {}
        self.__render_template("hw/control.vhd", params, "control.vhd")

        # Render engine file
        params = {}
        self.__render_template("hw/engine.vhd", params, "engine.vhd")
        
        self.logger.info("Compiling Resnnance model - OK")

    def __render_template(self, tmp_path, params, filename, subpath=None):
        # Connect layers and compile network
        template = self.env.get_template(tmp_path)
        content  = template.render(**params)

        # Write to file
        if subpath is None:
            subfile = filename
        else:
            subfile = os.path.join(subpath, filename)

        filepath = os.path.join(self.build_path, subfile)
        with open(filepath, mode="w", encoding="utf-8") as message:
            message.write(content)
            self.logger.info(f"Created {subfile}")

