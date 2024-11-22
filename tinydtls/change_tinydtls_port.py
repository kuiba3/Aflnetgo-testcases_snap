import sys

if len(sys.argv) > 1:
    port = str(sys.argv[1])

    f = open('./tests/config.h', 'w')

    content = "#define TEST_PORT " + port 
    f.write(content)

    f.close()


