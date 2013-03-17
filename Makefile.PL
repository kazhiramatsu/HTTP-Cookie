use inc::Module::Install;

name 'HTTP-Cookie';
all_from 'lib/HTTP/Cookie.pm';

configure_requires 'URI::Escape';

test_requires 'Test::More';
test_requires 'Test::Exception::LessClever';

WriteAll;

