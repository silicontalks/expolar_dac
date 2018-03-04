from pynq import DefaultIP

class tensorunit(DefaultIP):
    def __init__(self, description):
        super().__init__(description=description)
        
    bindto = ['EXPOLAR:user:tensorcore:1.0']
    
    def cfg_featsel(self, x, y):
        old = self.read(0x00)
        z1 = (((x<<28)& 0xf000_0000) + (old & 0x0fff_ffff))
        z2 = (((y<<26)& 0x0c00_0000) + (z1 & 0xf3ff_ffff))
        self.write(0x00, z2)
        
    def cfg_bias(self, bias):
        old = self.read(0x00)
        z1 = (((bias<<25)& 0x0200_0000) + (old & 0xfdff_ffff))
        self.write(0x00, z1)
        
    def cfg_wgtsel(self, wgt):
        old = self.read(0x00)
        z1 = (((wgt<<1)& 0x0000_0ffe) + (old & 0xffff_f001))
        self.write(0x00, z1)


    def weight(self, file):
        file_name = file
        base_addr = 256
        rel_addr = 32
        width = 4
        addr_feature_gen_bin(base_addr, rel_addr, width, file_name)
        list_addr, list_feature = addr_feature_gen_bin(base_addr, rel_addr, width, file_name)
        for i in range(len(list_addr)):
            tensor_stat.write(list_addr[i], list_feature[i])

    def feature(self, file):
        file_name = file
        base_addr = 4
        rel_addr = 8
        width = 4
        addr_feature_gen_hex(base_addr, rel_addr, width, file_name)
        list_addr, list_feature = addr_feature_gen_hex(base_addr, rel_addr, width, file_name)
        for i in range(len(list_addr)):
            tensor_stat.write(list_addr[i], list_feature[i])

    def bias(self, file):
        file_name = file
        base_addr = 96
        rel_addr = 8
        width = 4
        addr_feature_gen_hex(base_addr, rel_addr, width, file_name)
        list_addr, list_feature = addr_feature_gen_hex(base_addr, rel_addr, width, file_name)
        for i in range(len(list_addr)):
            tensor_stat.write(list_addr[i], list_feature[i])
            
    def conv3x3(self, width):
        txtName = 'output.txt'
        f = open(txtName, 'w+')
        for wgt in range(0,width):
            overlay.tensorcore_0.cfg_wgtsel(wgt)
            psum0 = tensor_stat.read(0x80)
            psum1 = tensor_stat.read(0x84)
            out_str = '%x'%psum0 + '%x'%psum1 + '\r\n'
            f.write(out_str)



def str2bin(x):
    res = 0
    for i in range(len(x)):
        res = res * 2 + int(x[i])
    return res


def str2hex(x):
    res = 0
    for i in range(len(x)):
        if x[i] >= 'a' and x[i] <= 'z':
            res = res*16 + ord(x[i])-87
        else:
            res = res * 16 + int(x[i])
    return res


def addr_feature_gen_bin(base_addr, rel_addr, width, file_name):
    list_addr = []
    list_feature = []
    fp = open(file_name, "r")
    r_str = fp.readline()
    while r_str != "":
        varlist = r_str.split()
        list_addr.append(base_addr)
        list_addr.append(base_addr + width)
        list_feature.append(str2bin(varlist[1]))
        list_feature.append(str2bin(varlist[0]))
        base_addr = base_addr + rel_addr
        r_str = fp.readline()
    fp.close()

    return list_addr, list_feature	

def addr_feature_gen_hex(base_addr, rel_addr, width, file_name):
    list_addr = []
    list_feature = []
    fp = open(file_name, "r")
    r_str = fp.readline()
    while r_str != "":
        varlist = r_str.split()
        list_addr.append(base_addr)
        list_addr.append(base_addr + width)
        list_feature.append(str2hex(varlist[0]))
        list_feature.append(str2hex(varlist[1]))
        base_addr = base_addr + rel_addr
        r_str = fp.readline()
    fp.close()

    return list_addr, list_feature	