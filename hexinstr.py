"""
Build hex instructions from assembly pseudocode.
Generates 32-bit hex-coded instructions

Usage: hexinstr.py [asm-file]

Assembly pseudocode: 
    (0.)[str INSTRUCTION] <-- Used for NOP and HALT
    1.  [str INSTRUCTION] [str MODE_MODIFIER][hexstr OPERAND]
    2.  [str INSTRUCTION] [str "R"+REGISTER_INDEX],
        [str MODE_MODIFIER][hexstr OPERAND]
    3.  [str INSTRUCTION] [str "R"+REG1_INDEX], [str "R"+REG2_INDEX]

Generates:
    (0.)[op-code (6 bit)][zeroes (24 bit)]
    1.  [op-code (6 bit)] [mode identification (3 bit)] [operand (23 bit)]
    2.  [op-code (6 bit)] [mode identification (3 bit)]
        [register index (4 bit)][operand (19 bit)]
    3.  [op-code (6 bit)] [mode 0 (3 bit)] [register index (4 bit)]
        [register index (4 bit)] [zeroes (15 bit)]

Example:
    LOAD R2, $FF =>

"""
import argparse  # Command line arguments
import re  # Variable parsing
from enum import Enum  # Error types
import os.path  # Check file existence

current_addr = 0x0
err_count = 0
var_table = {}

modes = {
    "": "0",   # No mode - format 3 (double registers)
    "$": "1",   # direct memory addressing
    "#": "2",   # Immediate (operand value)
    "(": "3",   # Indirect (follow operand addr)
    "I": "4",   # Indexed (follow operand + value of reg) only format 2
    }

# Since op-code has 6 bits, 64 instructions can be defined
# Rn/Rm: register with number, EA: effective address (use modes e.g. $FF)
instructions = {
    # INSTR : int format (0 to 3), hexstr OPCODE
    "NOP": [0, "00"],       # NOP
    "LOAD": [2, "01"],      # LOAD Rn, EA
    "STORE": [2, "02"],     # STORE Rn, EA
    "ADD": [2, "03"],       # ADD Rn, EA
    "ADD.R": [3, "04"],     # ADD.R Rn, Rm
    "SUB": [2, "05"],       # SUB Rn, EA
    "SUB.R": [3, "06"],     # SUB.R Rn, Rm
    "AND": [3, "07"],       # AND Rn, Rm
    "BRA": [1, "08"],       # BRA EA
    "BNE": [1, "09"],       # BRA EA
    "HALT": [0, "0A"],      # HALT
    "CMP": [3, "0B"],       # CMP Rn, Rm
    "BGE": [2, "0C"],       # BGE EA
    }


class Error(Enum):
    """ Used in debugging """
    FILE_ERROR = "File error"
    VAR_ERROR = "Variable access error"
    MODE_ERROR = "Adressing mode error"
    DEFINE_ERROR = "Variable definition error"
    FORMAT_ERROR = "Instruction format error"
    INSTR_ERROR = "Instruction error"
    SUBRDEF_ERROR = "Subroutine definition error"
    SUBR_ERROR = "Subroutine access error"
    REG_ERROR = "Register format error"


def check(predicate, info, err):
    """ Only signals, does not stop execution """
    global err_count
    if predicate:
        return True
    else:
        print("{} ({})".format(err.value, info))
        err_count += 1
        return False


""" UTILITY FUNCTIONS """


def ext_zeroes(seq, n):
    """ 
    Returns extended string
    with leading zeroes to length n 
    """
    while len(seq) < n:
        seq = "0" + seq
    return seq

def trim_name(seq):
    """ Trims variable or subroutine name """
    p = re.compile("[^A-Z|0-9|_]")
    return p.sub("", seq)

def is_hexchar(char):
    """ Determine if given character is valid hex """
    hexchars = list(map(lambda i: hex(i)[2:].upper(), range(16)))
    return char in hexchars


def trim_hex(hexstr):
    """ Returns string without any non-hex characters """
    retstr = [c for c in hexstr if is_hexchar(c)]
    return "".join(retstr)


def hex_to_bin(hexstr, n):
    """ Returns binary str of length n from hex string """
    # Hex str -> int -> binary w/o '0b' -> binary last n bits (truncates)
    short_binary = bin(int(hexstr, 16))[2:][-n:]
    extended = ext_zeroes(short_binary, n)  # Extends string
    return extended


def bin_to_hex(binstr):
    """ Returns hex string from binary string, chunking by 4 """
    chunks = [binstr[i:i+4] for i in range(0, len(binstr), 4)]
    hexstr = ""
    for chunk in chunks:
        hexc = hex(int(chunk, 2))[2:]
        hexstr += hexc.upper()
    return hexstr


""" SPECIAL LANGUAGE KEYWORDS """


def define_variable(words):
    """
    Keyword: define a var as hex value using %
    Example: DEF %i 5
    """
    if check(len(words) == 3 and words[0] == "DEF" and words[1][0] == "%", 
            words, Error.DEFINE_ERROR):
        var_table["%" + trim_name(words[1])] = trim_hex(words[2])


def define_subroutine(words):
    if check(len(words) == 2 and words[0] == ":" 
            and words[1] == trim_name(words[1]), 
            words, Error.SUBRDEF_ERROR):
        var_table[":"+words[1]] = hex(current_addr)[2:]


keywords = {"DEF": define_variable, ":": define_subroutine}


""" HEX CODE GENERATORS """


def generate_format_0(opcode_hex):
    """ Returns the opcode and zeroes """
    opcode = hex_to_bin(opcode_hex, 6)
    bit_str = opcode + "0"*24
    hex_str = bin_to_hex(bit_str)
    return hex_str


def generate_format_1(opcode_hex, operand):
    """
    Generates hex instruction string for given mode and operand, in format 1:
    OPCODE(6) MODE(3) OPERAND(23)
    """
    mode_identifier = operand[0]
    if not check(mode_identifier in modes, "mode1, {}".format(operand), Error.MODE_ERROR):
        return "0"
    mode = hex_to_bin(modes[mode_identifier], 3)
    opcode = hex_to_bin(opcode_hex, 6)

    operand = hex_to_bin(trim_hex(operand), 23)
    bit_str = opcode + mode + operand
    return bin_to_hex(bit_str)


def generate_format_2(opcode_hex, reg_index, operand):
    """
    Generates hex instruction string, format 2:
    OPCODE(6) MODE(3) REG(4) OPERAND(19)
    """
    mode_identifier = operand[0]
    if not check(mode_identifier in modes, "mode2, {}".format(operand), Error.MODE_ERROR):
        return "0"
    if not check(reg_index[0] == "R", "mode2, {}".format(reg_index), Error.REG_ERROR):
        return "0"
    mode = hex_to_bin(modes[mode_identifier], 3)
    opcode = hex_to_bin(opcode_hex, 6)

    operand = hex_to_bin(trim_hex(operand), 19)
    reg = hex_to_bin(trim_hex(reg_index), 4)
    bit_str = opcode + mode + reg + operand
    return bin_to_hex(bit_str)


def generate_format_3(opcode_hex, reg1, reg2):
    """
    Generates hex instruction string, format 3:
    OPCODE(6) zeroes(3) REG1(4) REG2(4) zeroes(15)
    """
    mode = "000"  # Mode not used for this
    opcode = hex_to_bin(opcode_hex, 6)
    reg1 = hex_to_bin(trim_hex(reg1), 4)
    reg2 = hex_to_bin(trim_hex(reg2), 4)
    bit_str = opcode + mode + reg1 + reg2 + "0"*15
    return bin_to_hex(bit_str)


""" INPUT PARSING """


def trim_line_to_words(line):
    """
    Trims comments and inserts variable values,
    returns word list split by space
    """
    line = line.upper()
    if "--" in line:
        line = line.split("--")[0]  # Trim away comments
    if line.split(" ")[0] not in keywords:
        # Replace %varname with var values if existing
        p = re.compile("%[A-Z|0-9|_]+")
        for match in p.finditer(line):
            if check(match.group() in var_table, match.group(), Error.VAR_ERROR):
                line = line.replace(match.group(), var_table[match.group()])
        # Replace :subrname with subroutine addr
        p = re.compile(":[A-Z|0-9|_]+")
        for match in p.finditer(line):
            if check(match.group() in var_table, match.group(), Error.SUBR_ERROR):
                line = line.replace(match.group(), var_table[match.group()])

    words = list(filter(None, line.split(" ")))
    return words


def parse_line(line, verbose=False):
    """ 
    Parses line using instruction table, prints hex 
    Line on format: (str instr_name, hexstr mode, hexstr operand)
    """
    global current_addr
    words = trim_line_to_words(line)
    if not words:  # Empty line
        return
    if words[0] in keywords:
        keywords[words[0]](words)
    else:
        if check(words[0] in instructions, line, Error.INSTR_ERROR):
            instruction = instructions[words[0]]
            instr_format = instruction[0]
            opcode_hex = instruction[1]
            hex_instr = ""
            if instr_format == 0:
                if check(len(words) == 1, words, Error.FORMAT_ERROR):
                    hex_instr = generate_format_0(opcode_hex)
            elif instr_format == 1:
                if check(len(words) == 2, words, Error.FORMAT_ERROR):
                    hex_instr = generate_format_1(opcode_hex, words[1])
            elif instr_format == 2:
                if check(len(words) == 3, words, Error.FORMAT_ERROR):
                    hex_instr = generate_format_2(opcode_hex, words[1], words[2])
            elif instr_format == 3:
                if check(len(words) == 3, words, Error.FORMAT_ERROR):
                    hex_instr = generate_format_3(opcode_hex, words[1], words[2])
            if verbose:
                print("{}: 0x{} (0b{}) from \"{}\"".format(
                    ext_zeroes(hex(current_addr)[2:], 8),
                    hex_instr,
                    hex_to_bin(hex_instr, 32),
                    line))
            else:
                print(hex_instr)
            current_addr += 0x4


def parse_file(file_name, verbose=False):
    """ Reads lines from file and passes them along """
    with open(file_name) as f:
        for line in f.readlines():
            parse_line(line.rstrip(), verbose)


def line_loop(verbose=False):
    """ Parses stdin lines until empty line """
    line = input()
    while line != "":
        parse_line(line, verbose)
        line = input()


if __name__ == "__main__":
    """ Parses arguments and starts either file or stdin parsing """
    parser = argparse.ArgumentParser(description="Convert assembly pseudocode to hex")
    parser.add_argument("-f", "--file")
    parser.add_argument("-v", "--verbose", action="store_true")
    args = parser.parse_args()
    if args.file:
        if check(os.path.exists(args.file), args.file, Error.FILE_ERROR):
            parse_file(args.file, args.verbose)
    else:
        line_loop(args.verbose)

    if args.verbose:
        print()
        print("Finished parsing, {} errors.".format(err_count))

