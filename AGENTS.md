# Intercal compiler

The first compilation of this compiler requires a intercal compiler in other stack, C, assembler, whatever.

## Doc

This requires a GitHub workflow to compile itself using previous released compiler, to release next version.

The intercal language documentation is at:
- http://catb.org/~esr/intercal/
- http://catb.org/~esr/intercal/THEORY.html
- http://catb.org/~esr/intercal/ick.htm
- http://catb.org/~esr/intercal/paper.html
- https://3e8.org/pub/intercal.pdf

Latest distribution download to compile first release with a intercal compiler:
- http://catb.org/~esr/intercal/intercal-0.30.tar.gz

Other doc to review:
- https://en.wikipedia.org/wiki/INTERCAL
- https://dev.to/viz-x/intercal-the-language-designed-to-mock-all-other-languages-2dlf
- https://earthly.dev/blog/intercal-yaml-and-other-horrible-programming-languages/
- https://en.wikipedia.org/wiki/COMEFROM#Hardware_implementation

## Roadmap

[ ] Document in AGENTS.md useful information about how to develop using intercal to know also what the compiler must do
[ ] Create a basic compiler with basic support to compile itself
[ ] Download an intercal compiler for first compilation and check if compiled executable can compile itself correctly and that one can work properly compiling itself again
[ ] Upload that first executable as a release to GitHub
[ ] Add a GitHub workflow that can download latest release binary to use it to compile the new version, then use the new version to compile itself, and release the new version
[ ] Improve the compiler and release it using the GitHub workflow

## Development

- Does NOT use gh cli, it is not available
- Request any additional detail you need or help/actions you need from user

### Examples that could be a test of this compiler, compiling and executing it

- https://github.com/leachim6/hello-world/blob/main/i/Intercal.i
- https://github.com/lazy-ninja/HELLO-INTERCAL/blob/master/ickhello.i
- http://progopedia.com/example/hello-world/259/

## Additional details

<... to be filled ...>
