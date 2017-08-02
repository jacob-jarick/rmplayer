#!/bin/bash

amixer --quiet set Master 5%-
amixer sget Master | grep %
