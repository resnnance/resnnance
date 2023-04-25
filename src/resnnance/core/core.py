import os
import jinja2
import logging
import networkx as nx

class Resnnance(object):

    def __init__(self):
        # Create templating environment
        self.env = jinja2.Environment(loader=jinja2.PackageLoader("resnnance.core", "templates"))

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

        # Log Resnnance core creation
        self.logger.info("Created new Resnnance core")

        # Build path
        self.build_path = "build"

        # Network data
        self.network = nx.DiGraph()

    def _create_snaps(self, num):
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

    def create_rsnn_engine(self):
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
        self._create_snaps(4)

        # Log slave creation
        self.logger.info(f"Created RISC-V Resnnance engine")

    def draw_network(self):
        pos = nx.spring_layout(self.network)

        # Draw
        node_sizes = [ndata['population'].size * 30 for node, ndata in self.network.nodes(data=True)]
        nx.draw(self.network, pos, with_labels=True, node_size=node_sizes)

        # Get connector name
        edge_labels = dict([((u, v), d['projection']._connector.__class__.__name__) for u, v, d in self.network.edges(data=True)])
        # Draw edge labels
        nx.draw_networkx_edge_labels(self.network, pos, edge_labels=edge_labels)
