use inc::Module::Install;
name 'Git-Release';
all_from 'lib/Git/Release.pm';

requires 'Git';

tests 't/*.t';
# author_tests 'xt';
# test_requires 'Test::More';
# auto_set_repository;

install_script $_ for <bin/*>;

auto_include;
WriteAll;
