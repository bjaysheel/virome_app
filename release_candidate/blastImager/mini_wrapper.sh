#!/bin/bash

exec /Library/WebServer/Documents/virome/blastImager/miniImager.pl $1 2>&1;
rm mini_temp.gif;
