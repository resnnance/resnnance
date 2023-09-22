from .logger import resnnance_logger

import os
import jinja2
import numpy as np

class ResnnanceCompiler(object):

    def __init__(self, build_path=None):
        # Log
        self.logger = resnnance_logger("compiler")

        # Create templating environment
        self.env = jinja2.Environment(loader=jinja2.PackageLoader("resnnance.core", "templates"))

        # Set default build path
        if not build_path == None:
            self.build_path = build_path

    def __create_snaps(self, num):
        # Create template from string
        template = self.env.get_template("hw/rsnn_snap.vhd")

        # Set up build directory
        if not os.path.exists(self.build_path):
            os.makedirs(self.build_path)

        # Set up snaps directory
        if not os.path.exists(os.path.join(self.build_path, "snaps")):
            os.makedirs(os.path.join(self.build_path, "snaps"))

        # Render template
        for i in range(num):
            # Set template parameters and render content
            params = {'entity_name': f"rsnn_snap_{i}", 'arch_name': 'arch'}
            content = template.render(**params)

            # Write to files
            filename = f"rsnn_snap_{i}.vhd"
            filepath = os.path.join(self.build_path, "snaps", filename)
            with open(filepath, mode="w", encoding="utf-8") as message:
                message.write(content)
                self.logger.info(f"Created rsnn_snap_{i}")

    def __create_rsnn_engine(self, model):
        # Fetch RISC-V templates
        templates = {
            'bus' : self.env.get_template("hw/sbus.vhd"),
            'engine' : self.env.get_template("hw/rsnn.vhd"),
            'core' : self.env.get_template("hw/rsnn_core.vhd")
        }

        # Set slave parameters
        params = {
            'bus': {
                'entity_name': "sbus",
            },
            'engine': {
                'entity_name': "rsnn",
                'core_name': "rsnn_core",
                'mem_depth': 8
            },
            'core': {
                'entity_name': "rsnn_core",
            }
        }

        # Set up build directory
        if not os.path.exists(self.build_path):
            os.makedirs(self.build_path)

        # Render and write to files
        for name, template in templates.items():
            # Render content
            content = template.render(**params[name])

            # Generate file path
            filename = f"{params[name]['entity_name']}.vhd"
            filepath = os.path.join(self.build_path, filename)

            # Write to file
            with open(filepath, mode="w", encoding="utf-8") as module:
                module.write(content)
                self.logger.info(f"Created {params[name]['entity_name']}")

        # Create snaps
        self.__create_snaps(4)

        # Log slave creation
        self.logger.info(f"Created RISC-V Resnnance engine")

    def compile(self, model, path=None):
        self.logger.info("Compiling Resnnance model...")

        # Set build path
        if not path == None:
            self.build_path = path

        # Initialize model
        self.map = {layer.label: {'layer': layer} for layer in model.layers}

        for layer in model.layers:
            # Get all projections pointing to this layer
            inprojections = [conn for conn in model.connections if conn.post == layer]

            # Read incoming projections
            for inproj in inprojections:
                # Create weight matrix for incoming projection
                self.map[layer.label]['weights'] = np.zeros(inproj.shape)

                # Fill matrix with weights
                for conn in inproj.connections:
                    # Map projection connection weights into matrix (M, N): M = # synapses/pre neurons, N = # post neurons
                    self.map[layer.label]['weights'][conn.presynaptic_index, conn.postsynaptic_index] = conn.weight

                # Print connections
                #import matplotlib.pyplot as plt
                #plt.imshow(self.map[layer.label]['weights'], interpolation='none')
                #plt.show()

        # Create engine from model
        self.__create_rsnn_engine(model)
        
        self.logger.info("Compiling Resnnance model - OK")
