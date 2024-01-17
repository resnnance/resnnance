import numpy as np

DEFAULT = 1

class Layer(object):
    templates = None

    def __init__(self, label, info=None):
        raise NotImplementedError

    def set_layer(self, info):
        raise NotImplementedError
    
    def get_size(self):
        raise NotImplementedError

    def get_logn(self):
        raise NotImplementedError

    def get_template_params(self):
        """
        Returns all needed parameters for the generation of a VHDL
        template
        """
        raise NotImplementedError

class Input(Layer):
    templates = {
        'core':    "hw/layers/input.vhd",
        'weights': "hw/layers/input_weights.vhd"
    }

    def __init__(self, label, info=None):
        self.label = "layer_" + label

        if info is None:
            self.weights = None
        else:
            self.set_layer(info)
    
    def set_layer(self, info):
        if info.ndim == 1:
            self.weights = info     # Dense weight matrix
        else:
            raise ValueError('Wrong weight matrix shape')

    def get_size(self):
        if self.weights is None:
            return DEFAULT
        else:
            return self.weights.shape[0]

    def get_logn(self):
        if self.weights is None:
            return DEFAULT
        else:
            return int(np.ceil(np.log2(self.weights.shape[0])))

    def get_template_params(self):
        params = {
            'core': {
                'name': self.label,
                'weights': self.label + "_weights",
                'logn': self.get_logn()
            },
            'weights': {
                'name': self.label + "_weights",
                'weights': self.weights,
                'n': self.get_size()
            }
        }
        return params

class Dense(Layer):
    templates = {
        'core':    "hw/layers/dense.vhd",
        'weights': "hw/layers/dense_weights.vhd"
    }

    def __init__(self, label, info=None):
        self.label = "layer_" + label

        if info is None:
            self.weights = None
        else:
            self.set_layer(info)
    
    def set_layer(self, info):
        if info.ndim == 2:
            self.weights = info     # Dense weight matrix
        else:
            raise ValueError('Wrong weight matrix shape')

    def get_logn(self):
        if self.weights is None:
            return DEFAULT
        else:
            return int(np.ceil(np.log2(self.weights.shape[1])))

    def get_size(self):
        if self.weights is None:
            return DEFAULT
        else:
            return len(self.weights.flatten())

    def get_template_params(self):
        params = {
            'core': {
                'name': self.label,
                'weights': self.label + "_weights",
                'logm': int(np.ceil(np.log2(self.weights.shape[0]))),
                'logn': self.get_logn()
            },
            'weights': {
                'name': self.label + "_weights",
                'weights': self.weights,
                'm': self.weights.shape[0],
                'n': self.weights.shape[1]
            }
        }
        return params

class Conv2D(Layer):
    templates = {
        'core':   "hw/layers/conv2d.vhd",
        'weights': "hw/layers/conv2d_weights.vhd"
    }

    def __init__(self, label, info=None):
        self.label = "layer_" + label

        if info is None:
            self.input_shape = None
            self.kernel_shape = None
            self.weights = None
            self.padding = None
            self.strides = None
        else:
            self.set_layer(info)

    def __get_output_shape(self):
        ny, nx, nz    = self.input_shape
        ky, kx, kz, f = self.kernel_shape
        sy, sx        = self.strides

        if self.padding == 'valid':    # No padding
            return (ny - ky + 1) // sy, (nx - kx + 1) // sx, f
        elif self.padding == 'same':   # Padding generates same sized output
            return ny // sy, nx // sx, f

    def __get_inital_position(self):
        ky, kx, kz, f = self.kernel_shape

        if self.padding == 'valid':    # No padding
            return (ky - 1) // 2, (kx + 1) // 2
        elif self.padding == 'same':   # Padding generates same sized output
            return 0, 0

    def __get_lbuffer_len(self):
        ny, nx, nz    = self.input_shape
        ky, kx, kz, f = self.kernel_shape

        return ((ky - 1) * nx + kx) * nz

    def __get_synapses(self):
        ny, nx, nz = self.input_shape
        return ny * nx * nz

    def __flatten_zy(self):
        #
        #         #-----------------#
        #         | c00 | c01 | c02 |
        #     #-----------------# --|
        #     | b00 | b01 | b02 | 2 |
        # #-----------------# --| --|
        # | a00 | a01 | a02 | 2 | 2 |
        # |-----|-----|-----| --| --#
        # | a10 | a11 | a12 | 2 |
        # |-----|-----|-----| --#
        # | a20 | a21 | a22 |
        # #-----------------#
        #
        #          ||  .flatten (z, y)
        #          \/
        #
        # [a00, b00, c00, a01, b01, c01, ... , a22, b22, c22]

        kernels = []
        ky, kx, kz, f = self.kernel_shape

        for kernel in self.weights:
            flat = np.empty(ky * kx)

            for i, row in enumerate(kernel):
                for j, col in enumerate(row):
                    flat = np.concatenate((flat, kernel[i,j,:]))
            kernels.append(flat)

        return kernels

    def set_layer(self, info):
        self.input_shape = info['input_shape']
        self.kernel_shape = info['kernel_shape']
        self.weights = [info['weights'][:,:,:,i] for i in range(info['weights'].shape[3])]
        self.padding = info['padding']
        self.strides = info['strides']

    def get_size(self):
        if self.weights is None:
            return DEFAULT
        else:
            return sum([len(kernel.flatten()) for kernel in self.weights])

    def get_logm(self):
        ny, nx, nz = self.input_shape
        return int(np.ceil(np.log2(ny * nx * nz)))

    def get_logn(self):
        my, mx, f = self.__get_output_shape()
        return int(np.ceil(np.log2(my * mx * f)))

    def get_template_params(self):
        params = {
            'core': {
                'name': self.label,
                'weights': self.label + "_weights",
                'logm': self.get_logm(),
                'logn': self.get_logn(),
                'syn': self.__get_synapses(),
                'n': self.input_shape,          # (ny, nx, nz)
                'k': self.kernel_shape,         # (ky, kx, 1, f)
                'p': self.padding,
                's': self.strides,              # (sy, sx)
                'm': self.__get_output_shape(), # (my, mx, f)
                'l': self.__get_lbuffer_len()   # l
            },
            'weights': {
                'name': self.label + "_weights",
                'k': self.kernel_shape,         # (ky, kx, 1, f)
                'weights': self.__flatten_zy()
            }
        }
        return params

class Pooling(Layer):
    templates = {
        'core': "hw/layers/pooling.vhd"
    }

    def __init__(self, label, info=None):
        self.label = "layer_" + label

        if info is None:
            self.n = None
            self.stride = None
            self.pool = None
        else:
            self.set_layer(info)

    def set_layer(self, info):
        self.n = info['n']              # Input dimensions (y,x,z)
        self.stride = info['stride']    # Stride steps (y,x)
        self.pool = info['pool']        # Pool size (y,x)

    def get_weight(self):
        return 1 / (self.pool[0] * self.pool[1])

    def get_size(self):
        if self.pool is None:
            return DEFAULT
        else:
            return self.pool[0] * self.pool[1] 

    def get_logn(self):
        if self.pool is None:
            return DEFAULT
        else:
            return 1

    def get_template_params(self):
        params = {
            'core': {
                'name': self.label,
                'n': self.n,
                'stride': self.stride,
                'pool': self.pool
            }
        }
        return params