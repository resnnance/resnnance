from pyNN import recording

from resnnance.pyNN import simulator

class Recorder(recording.Recorder):
    _simulator = simulator


