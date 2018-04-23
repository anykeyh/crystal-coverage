echo "Building crystal-coverage binary"

mkdir -p ../../bin

crystal build --release src/coverage/cli.cr -o ../../bin/crystal-coverage

echo "Completed. To test with coverage, run bin/crystal-coverage"
echo "Get documentations on https://github.com/anykeyh/crystal-coverage"