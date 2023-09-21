from .logger   import resnnance_logger
from .compiler import ResnnanceCompiler
from .plotter  import ResnnancePlotter

class Resnnance(object):

    def __init__(self):
        # Logger
        self.logger = resnnance_logger("resnnance")

        # Model build
        self.compiler = ResnnanceCompiler()

        # Plotter
        self.plotter = ResnnancePlotter()

        # Model data
        self.logger.info("Creating empty Resnnance model...")
        self.layers = []
        self.connections = []
        self.logger.info("Creating empty Resnnance model - OK")

    def compile(self, path=None):
        # Set new build path if given
        if not path == None:
            self.compiler.set_build_path(path)

        # Compile
        self.compiler.compile(self)

    def plot(self, path):
        self.plotter.plot(self, path)