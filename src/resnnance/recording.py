from pyNN import recording

from resnnance import simulator

class Recorder(recording.Recorder):
    _simulator = simulator


