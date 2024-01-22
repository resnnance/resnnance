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
        'core': "hw/layers/input/poisson_core.vhd",
        'aux':  "hw/layers/input/poisson_aux.vhd"
    }

    def __init__(self, label, info=None):
        self.label = "layer_" + label

        if info is None:
            self.n = None
        else:
            self.set_layer(info)
    
    def set_layer(self, info):
        self.n = info     # Neuron outputs

    def get_size(self):
        if self.n is None:
            return DEFAULT
        else:
            return self.n

    def get_logn(self):
        if self.n is None:
            return DEFAULT
        else:
            return int(np.ceil(np.log2(self.n)))

    def get_template_params(self):
        params = {
            'core': {'name': self.label},
            'aux': {
                'name': self.label,
                'n': self.get_size()
            }
        }
        return params

class Dense(Layer):
    templates = {
        'core':    "hw/layers/fc/fc_core.vhd",
        'config':  "hw/layers/fc/fc_config.vhd",
        'ctrl':    "hw/layers/fc/ctrl/fc_ctrl.vhd",
        'npu_aux': "hw/layers/fc/npu/fc_npu_aux.vhd",
        'npu':     "hw/layers/fc/npu/fc_npu.vhd"
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

    def get_size(self):
        if self.weights is None:
            return DEFAULT
        else:
            return len(self.weights.flatten())

    def get_logn(self):
        if self.weights is None:
            return DEFAULT
        else:
            return int(np.ceil(np.log2(self.weights.shape[1])))

    def get_template_params(self):
        params = {
            'core':    {'name': self.label},
            'ctrl':    {'name': self.label},
            'npu_aux': {'name': self.label},
            'npu':     {'name': self.label},
            'config': {
                'name': self.label,
                'weights': self.weights,
                'm': self.weights.shape[0],
                'n': self.weights.shape[1]
            }
        }
        return params

class Conv2D(Layer):
    templates = {
        'core':    "hw/layers/conv2D/conv2D_core.vhd",
        'config':  "hw/layers/conv2D/conv2D_config.vhd",
        'ctrl':    "hw/layers/conv2D/ctrl/conv2D_ctrl.vhd",
        'npu_aux': "hw/layers/conv2D/npu/conv2D_npu_aux.vhd",
        'npu':     "hw/layers/conv2D/npu/conv2D_npu.vhd"
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
        my, mx, mz    = self.input_shape
        ky, kx, kz, f = self.kernel_shape
        sy, sx        = self.strides

        if self.padding == 'valid':    # No padding
            return (my - ky + 1) // sy, (mx - kx + 1) // sx, f
        elif self.padding == 'same':   # Padding generates same sized output
            return my // sy, mx // sx, f

    def __get_inital_position(self):
        ky, kx, kz, f = self.kernel_shape

        if self.padding == 'valid':    # No padding
            return (ky - 1) // 2, (kx + 1) // 2
        elif self.padding == 'same':   # Padding generates same sized output
            return 0, 0

    def __get_lbuffer_len(self):
        my, mx, mz    = self.input_shape
        ky, kx, kz, f = self.kernel_shape

        return ((ky - 1) * mx + kx) * mz

    def __get_synapses(self):
        my, mx, mz = self.input_shape
        return my * mx * mz

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
            flat = np.empty(0)

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
        my, mx, mz = self.input_shape
        return int(np.ceil(np.log2(my * mx * mz)))

    def get_logn(self):
        ny, nx, f = self.__get_output_shape()
        return int(np.ceil(np.log2(ny * nx * f)))

    def get_template_params(self):
        params = {
            'core':    {'name': self.label},
            'ctrl':    {'name': self.label},
            'npu_aux': {'name': self.label},
            'npu':     {'name': self.label},
            'config': {
                'name': self.label,
                'm': self.input_shape,          # (my, mx, mz)
                'k': self.kernel_shape,         # (ky, kx, kz, f)
                #'s': self.strides,              # (sy, sx)
                'n': self.__get_output_shape(), # (ny, nx, f)
                'weights': self.__flatten_zy()
            }
        }
        return params


class Pooling(Layer):
    templates = {}
    #templates = {
    #    'core':    "hw/layers/pool/pool_core.vhd",
    #    'config':  "hw/layers/pool/pool_config.vhd",
    #    'ctrl':    "hw/layers/pool/ctrl/pool_ctrl.vhd",
    #    'npu_aux': "hw/layers/pool/npu/pool_npu_aux.vhd",
    #    'npu':     "hw/layers/pool/npu/pool_npu.vhd"
    #}

    def __init__(self, label, info=None):
        self.label = "layer_" + label

        if info is None:
            self.input_shape = None
            self.pool = None
        else:
            self.set_layer(info)

    def __get_output_shape(self):
        my, mx, mz    = self.input_shape
        py, px        = self.pool

        return my // py, mx // px, mz

    def __get_weight(self):
        return 1 / (self.pool[0] * self.pool[1])

    def set_layer(self, info):
        self.input_shape = info['input_shape']  # Input dimensions (y,x,z)
        self.pool = info['pool_size']           # Pool size (y,x)

    def get_size(self):
        return self.pool[0] * self.pool[1] 

    def get_logn(self):
        ny, nx, mz = self.__get_output_shape()
        return int(np.ceil(np.log2(ny * nx * mz)))

    def get_template_params(self):
        params = {
            'core':    {'name': self.label},
            'ctrl':    {'name': self.label},
            'npu_aux': {'name': self.label},
            'npu':     {'name': self.label},
            'config': {
                'name': self.label,
                'm': self.input_shape,          # (my, mx, mz)
                'p': self.pool,                 # (py, px)
                'n': self.__get_output_shape(), # (ny, nx, mz)
                'weight': self.__get_weight()
            }
        }
        return params