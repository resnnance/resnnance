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

        # Compile model
        #   One snap per layer
        #   One network wrapper
        #   One network controller
        #   One engine (RISC-V peripheral)

        # Compile layers
        [self.__render_layer(layer, "layers") for layer in model.layers]

        # Connect layers and render network file
        params = {
            'layers': [
                {'label': layer.label, 'logn': layer.get_logn()}
                for layer in model.layers
            ],
        }
        self.__render_template("hw/network.vhd", params, "network.vhd")

        # Render simtick file
        params = {}
        self.__render_template("hw/simtick.vhd", params, "simtick.vhd")

        # Render controller file
        params = {}
        self.__render_template("hw/control.vhd", params, "control.vhd")

        # Render engine file
        params = {}
        self.__render_template("hw/engine.vhd", params, "engine.vhd")
        
        self.logger.info("Compiling Resnnance model - OK")

    def __render_template(self, tmppath, params, filename, subpath=None):
        template = self.env.get_template(tmppath)
        content  = template.render(**params)

        # Write to file
        if subpath is None:
            subfile = filename
        else:
            subfile = os.path.join(subpath, filename)

            # Generate directories for subpath
            if not os.path.exists(os.path.join(self.build_path, subpath)):
                os.makedirs(os.path.join(self.build_path, subpath))

        # Create complete filepath
        filepath = os.path.join(self.build_path, subfile)

        with open(filepath, mode="w", encoding="utf-8") as message:
            message.write(content)
            self.logger.info(f"Created {subfile}")

    def __render_layer(self, layer, subpath=None):
        """
        Renders a layer into a set of VHDL files
        defined from templates in the layer class
        """

        # Render all layer templates
        for key, tmppath in layer.templates.items():
            # Get layer parameters for each template
            params = layer.get_template_params()[key]
            # Render each layer template
            self.__render_template(tmppath, params, f"{params['name']}.vhd", subpath)