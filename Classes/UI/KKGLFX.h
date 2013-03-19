//
//  KKGLFX.h
//  Be2
//
//  Created by Alessandro Iob on 2/5/10.
//  Copyright 2010 Kismik. All rights reserved.
//

#include <OpenGLES/ES1/gl.h>
#include <OpenGLES/ES1/glext.h>

// A simple vertex format
typedef struct {
	GLfloat x, y, s, t;
} V2fT2f;


void brightnessFull (float t); // t [0..2]
void brightness (V2fT2f *quad, float t); // t [0..2]

void contrastFull (float t); // t [0..2]
void contrast (V2fT2f *quad, float t); // t [0..2]

void greyscaleFull (float t);// t = 1 for standard perceptual weighting
void greyscale (V2fT2f *quad, float t);// t = 1 for standard perceptual weighting

void hueFull (float t); // t [0..2] == [-180..180] degrees
void hue (V2fT2f *quad, float t); // t [0..2] == [-180..180] degrees
