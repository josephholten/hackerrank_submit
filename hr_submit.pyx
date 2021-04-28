import os
import sys
from sys import argv
from datetime import datetime

# FIXME: remove includes from impl file
# FIXME: insert impl file directly as an associated file to header
# FIXME: comment out the auto lambdas

assert len(argv) == 2
argv.pop(0)  # removes the filename

WARN_ON_COUT = True
# keywords = ["LOG", "INSERT", "TESTING"]

submission_file_path = os.path.basename(argv[0])
submission_file_path = submission_file_path[:submission_file_path.rfind(".")] + "_submission.cpp"

compliant = lambda *args, **kwargs: True  # check wether filepath is ok

while os.path.isfile(submission_file_path) and compliant(submission_file_path):
    response = input(f"out file already exists ({submission_file_path}), overwrite? [Y/n/file_path] ")
    if response.lower() in {"n", "no"}:
        print("aborting.")
        sys.exit()
    if response.lower().strip() in {"", "y", "yes"}:
        break  # continue on as nothing were

    print("taking response as new file_name...")
    submission_file_path = os.path.abspath(response)

aux_file_name = "hr_submit_auxiliary_file"

headers = []
impls = []


def match_against(pos, check, match):
    return check[pos:pos + len(match)] == match


with open(argv[0]) as source_file, open(aux_file_name, "w") as aux_file:
    write_line = True
    for line_number, line in enumerate(source_file, start=1):
        # check for comment
        comment_idx = line.find("//")
        if comment_idx != -1:  # includes a comment in the line
            # comment is immediately succeded by keyword
            comment_idx += 2  # move to after "//"
            while line[comment_idx] == " ":  # "eat" up whitespace following the "//" immediately
                comment_idx += 1
            if match_against(comment_idx, line, "LOG"):  # line only logs stuff to console
                continue
            if match_against(comment_idx, line, "INSERT"):  # need to insert header for hackerrank
                if line.find("#include") == -1:
                    print(f"Syntax error in line {line_number}: you wrote 'INSERT' in  but no '#include' found.")
                    continue

                quote_start = line.find("\"")
                if quote_start == -1:
                    print(f"Syntax error in line {line_number}: you wrote 'INSERT' in  but no quotes were found.")
                    continue
                quote_start += 1
                quote_end = line.find("\"", quote_start)
                if quote_end == -1:
                    print(f"Syntax error in line {line_number}: found 'INSERT'  but no closing quote was found.")
                    continue

                path = line[quote_start:quote_end]
                assert compliant(path, header=True), \
                    f"line {line_number}: non compliant, possibly malicious header path encountered"

                if path[path.rfind(".") + 1:] == "h":
                    headers.append(path)
                    continue
                if path[path.rfind(".") + 1:] == "cpp":
                    impls.append(path)
                    continue
            if match_against(comment_idx, line, "TESTING"):
                write_line = False
            if match_against(comment_idx, line, "--TESTING"):
                write_line = True
                continue

        if write_line:
            # write it first to aux file, then copy it into out file, since header needs to be written first
            aux_file.write(line)

with open(submission_file_path, "w") as out_file:
    # write little intro
    out_file.write(f"// CREATED FILE AT {datetime.now()}")

    # first write headers
    for header_path in headers:
        with open(header_path) as header_file:
            out_file.write(f"\n// INSERTING HEADER FILE {header_path}\n\n")
            for header_line in header_file:
                out_file.write(header_line)
            out_file.write(f"\n// -- INSERTING HEADER FILE {header_path}\n\n")

    # then write implementations
    # FIXME: Horrible syntax finding, either do through regex, or through something advanced
    # FIXME: doesn't work on the custom headers, too late, to fix :/
    for impl_path in impls:
        with open(impl_path) as impl_file:
            out_file.write(f"\n// INSERTING IMPLEMENTATION FILE {impl_path}\n\n")
            for impl_line in impl_file:
                if impl_line.find("#include") != -1:
                    quote_start = impl_line.find("\"")
                    if quote_start != -1:
                        quote_start += 1
                        quote_end = impl_line.find("\"", quote_start+1)
                        if quote_end != -1:
                            if line[quote_start:quote_end] in headers:
                                continue  # don't load custom headers

                out_file.write(impl_line)
            out_file.write(f"\n// -- INSERTING IMPLEMENTATION FILE {impl_path}\n\n")

    out_file.write(f"\n// INSERTING ACTUAL SOURCE")
    with open(aux_file_name) as aux_file:
        for line in aux_file:
            out_file.write(line)

os.remove(aux_file_name)
print(f"written formatted file to {submission_file_path}")
