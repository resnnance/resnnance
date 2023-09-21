class Layer(object):
    pass

class Conv2D(Layer):
    pass

class Pooling(Layer):
    pass

class Dense(Layer):

    def __init__(self, weights):
        self.weights = weights