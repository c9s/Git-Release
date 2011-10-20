use inc::Module::Install;
name 'Git-Release';
all_from 'lib/Git/Release.pm';

# requires '';

tests 't/*.t';
# author_tests 'xt';
# test_requires 'Test::More';
# auto_set_repository;

install_script 'bin/git-ready';
install_script 'bin/git-ready-close';
install_script 'bin/git-ready-close-all';
install_script 'bin/git-ready-merge';

auto_include;
WriteAll;
