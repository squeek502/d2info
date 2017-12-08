-- Fast functions for working with binary data
return {
    decode_uint8 = function(str, ofs)
        ofs = ofs or 0
        return string.byte(str, ofs + 1)
    end,

    decode_uint16 = function(str, ofs)
        ofs = ofs or 0
        local a, b = string.byte(str, ofs + 1, ofs + 2)
        return a + b * 0x100
    end,

    decode_uint32 = function(str, ofs)
        ofs = ofs or 0
        local a, b, c, d = string.byte(str, ofs + 1, ofs + 4)
        return a + b * 0x100 + c * 0x10000 + d * 0x1000000
    end,

    encode_uint8 = function(int)
        return string.char(int)
    end,

    encode_uint16 = function(int)
        local a, b = int % 0x100, int / 0x100
        return string.char(a, b)
    end,

    encode_uint32 = function(int)
        local a, b, c, d = 
            int % 0x100, 
            int / 0x100 % 0x100, 
            int / 0x10000 % 0x100, 
            int / 0x1000000
        return string.char(a, b, c, d)
    end,

    hex_dump = function(buf)
        for i=1,math.ceil(#buf/16) * 16 do
            if (i-1) % 16 == 0 then io.write(string.format('%08X  ', i-1)) end
            io.write( i > #buf and '   ' or string.format('%02X ', buf:byte(i)) )
            if i %  8 == 0 then io.write(' ') end
            if i % 16 == 0 then io.write( buf:sub(i-16+1, i):gsub('%c','.'), '\n' ) end
        end
    end,

    null_terminate = function(buf)
        return string.format("%s", buf)
    end,
}