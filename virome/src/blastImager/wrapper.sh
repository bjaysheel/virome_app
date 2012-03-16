#!/bin/bash

exec /Library/WebServer/Documents/virome/blastImager/blastImager.pl $1 2>&1;
rm temp.gif;