from .logger import resnnance_logger

import os, shutil
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

        # Create build skeleton
        self.__build_skeleton()
        self.__build_files()

        # Render layers
        [self.__render_layer(layer, os.path.join("src", "layers")) for layer in model.layers]

        # Render simtick file
        params = {}
        self.__render_template(os.path.join("hw", "simtick.vhd"), params, os.path.join("src", "simtick.vhd"))

        # Connect layers and render network file
        params = {
            'name':   'network',
            'layers': [{'label': layer.label, 'logn': layer.get_logn()} for layer in model.layers]
        }
        self.__render_template(os.path.join("hw", "network.vhd"), params, os.path.join("src", "network.vhd"))
        
        # Render build test list
        self.__render_template(os.path.join("build", "test", "CMakeLists.txt"), params, os.path.join("test", "CMakeLists.txt"))

        # Render build list
        self.__render_template(os.path.join("build", "CMakeLists.txt"), params, "CMakeLists.txt")

        self.logger.info("Compiling Resnnance model - OK")


    def __build_skeleton(self):
        directories = ['src', 'doc', 'test']

        for subd in directories:
            # Generate directories for subpath
            if not os.path.exists(os.path.join(self.build_path, subd)):
                os.makedirs(os.path.join(self.build_path, subd))


    def __build_files(self):
        ppath = os.path.dirname(__file__)
        shutil.copytree(os.path.join(ppath, "templates/build/cmake"), os.path.join(self.build_path, "cmake"), dirs_exist_ok=True)
        shutil.copy(os.path.join(ppath, "templates/build/build.sh"), os.path.join(self.build_path, "build.sh"))


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
            self.__render_template(tmppath, params, f"{params['name']}_{key}.vhd",
                                   os.path.join(subpath, f"{layer.label}"))