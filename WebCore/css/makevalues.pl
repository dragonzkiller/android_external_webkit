#! /usr/bin/perl
#
#   This file is part of the WebKit project
#
#   Copyright (C) 1999 Waldo Bastian (bastian@kde.org)
#   Copyright (C) 2007 Apple Inc. All rights reserved.
#   Copyright (C) 2008 Nokia Corporation and/or its subsidiary(-ies)
#   Copyright (C) 2010 Andras Becsi (abecsi@inf.u-szeged.hu), University of Szeged
#
#   This library is free software; you can redistribute it and/or
#   modify it under the terms of the GNU Library General Public
#   License as published by the Free Software Foundation; either
#   version 2 of the License, or (at your option) any later version.
#
#   This library is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#   Library General Public License for more details.
#
#   You should have received a copy of the GNU Library General Public License
#   along with this library; see the file COPYING.LIB.  If not, write to
#   the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
#   Boston, MA 02110-1301, USA.
use strict;
use warnings;

open NAMES, "<CSSValueKeywords.in" || die "Could not open CSSValueKeywords.in";
my @names = ();
while (<NAMES>) {
  next if (m/(^#)|(^\s*$)/);
  # Input may use a different EOL sequence than $/, so avoid chomp.
  $_ =~ s/[\r\n]+$//g;
  push @names, $_;
}
close(NAMES);

open GPERF, ">CSSValueKeywords.gperf" || die "Could not open CSSValueKeywords.gperf for writing";
print GPERF << "EOF";
%{
/* This file is automatically generated from CSSValueKeywords.in by makevalues, do not edit */

#include \"CSSValueKeywords.h\"
%}
%struct-type
struct Value;
%omit-struct-type
%language=C++
%readonly-tables
%compare-strncmp
%define class-name CSSValueKeywordsHash
%define lookup-function-name findValueImpl
%define hash-function-name value_hash_function
%define word-array-name value_word_list
%includes
%enum
%%
EOF

foreach my $name (@names) {
  my $id = $name;
  $id =~ s/(^[^-])|-(.)/uc($1||$2)/ge;
  print GPERF $name . ", CSSValue" . $id . "\n";
}
print GPERF "%%\n";
close GPERF;

open HEADER, ">CSSValueKeywords.h" || die "Could not open CSSValueKeywords.h for writing";
print HEADER << "EOF";
/* This file is automatically generated from CSSValueKeywords.in by makevalues, do not edit */

#ifndef CSSValueKeywords_h
#define CSSValueKeywords_h

#include <string.h>

namespace WebCore {

const int CSSValueInvalid = 0;
EOF

my $i = 1;
my $maxLen = 0;
foreach my $name (@names) {
  my $id = $name;
  $id =~ s/(^[^-])|-(.)/uc($1||$2)/ge;
  print HEADER "const int CSSValue" . $id . " = " . $i . ";\n";
  $i = $i + 1;
  if (length($name) > $maxLen) {
    $maxLen = length($name);
  }
}
print HEADER "const int numCSSValueKeywords = " . $i . ";\n";
print HEADER "const size_t maxCSSValueKeywordLength = " . $maxLen . ";\n";
print HEADER << "EOF";

const char* getValueName(unsigned short id);

} // namespace WebCore

#endif // CSSValueKeywords_h

EOF
close HEADER;

system("gperf --key-positions=\"*\" -D -n -s 2 CSSValueKeywords.gperf > CSSValueKeywordsHash.h") == 0 || die "calling gperf failed: $?";

open C, ">>CSSValueKeywordsHash.h" || die "Could not open CSSValueKeywordsHash.h for writing";
print C  "static const char * const valueList[] = {\n";
print C  "\"\",\n";
foreach my $name (@names) {
  print C  "\"" . $name . "\", \n";
}
print C << "EOF";
    0
};

EOF

close C;

my $valueKeywordsImpl = "CSSValueKeywords.cpp";

open VALUEKEYWORDS, ">$valueKeywordsImpl" || die "Could not open $valueKeywordsImpl for writing";
print VALUEKEYWORDS << "EOF";
/* This file is automatically generated by make-hash-tools.pl, do not edit */

#include "CSSValueKeywords.h"
#include "HashTools.h"

namespace WebCore {
#include "CSSValueKeywordsHash.h"

const Value* findValue (register const char* str, register unsigned int len)
{
    return CSSValueKeywordsHash::findValueImpl(str, len);
}

const char* getValueName(unsigned short id)
{
    if (id >= numCSSValueKeywords || id <= 0)
        return 0;
    return valueList[id];
}

} // namespace WebCore

EOF

close VALUEKEYWORDS;

