//
//  KKGLFX.m
//  Be2
//
//  Created by Alessandro Iob on 2/5/10.
//  Copyright 2010 Kismik. All rights reserved.
//

#import "KKGLFX.h"

#include <math.h>

// Geometry for a fullscreen quad
V2fT2f fullquad[4] = {
{ 0, 0, 0, 0 },
{ 1, 0, 1, 0 },
{ 0, 1, 0, 1 },
{ 1, 1, 1, 1 },
};

// Geometry for a fullscreen quad, flipping texcoords upside down
V2fT2f flipquad[4] = {
{ 0, 0, 0, 1 },
{ 1, 0, 1, 1 },
{ 0, 1, 0, 0 },
{ 1, 1, 1, 0 },
};

// The following filters change the TexEnv state in various ways.
// To reduce state change overhead, the convention adopted here is
// that each filter is responsible for setting up common state, and
// restoring uncommon state to the default.
//
// Common state for this application is defined as:
// GL_TEXTURE_ENV_MODE
// GL_COMBINE_RGB, GL_COMBINE_ALPHA
// GL_SRC[012]_RGB, GL_SRC[012]_ALPHA
// GL_TEXTURE_ENV_COLOR
//
// Uncommon state for this application is defined as:
// GL_OPERAND[012]_RGB, GL_OPERAND[012]_ALPHA
// GL_RGB_SCALE, GL_ALPHA_SCALE
//
// For all filters, the texture's alpha channel is passed through unchanged.
// If you need the alpha channel for compositing purposes, be mindful of
// premultiplication that may have been performed by your image loader.

#pragma mark -
#pragma mark GL States

static int textureEnvMode;
static int combineRGB;
static int src0RGB;
static int src1RGB;
static int combineAlpha;
static int src0Alpha;

void GLFXPushState ()
{
	glGetTexEnviv (GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, &textureEnvMode);
	glGetTexEnviv (GL_TEXTURE_ENV, GL_COMBINE_RGB, &combineRGB);
	glGetTexEnviv (GL_TEXTURE_ENV, GL_SRC0_RGB, &src0RGB);
	glGetTexEnviv (GL_TEXTURE_ENV, GL_SRC1_RGB, &src1RGB);
	glGetTexEnviv (GL_TEXTURE_ENV, GL_COMBINE_ALPHA, &combineAlpha);
	glGetTexEnviv (GL_TEXTURE_ENV, GL_SRC0_ALPHA, &src0Alpha);
}

void GLFXPopState ()
{
	glTexEnvi (GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, textureEnvMode);
	glTexEnvi (GL_TEXTURE_ENV, GL_COMBINE_RGB, combineRGB);
	glTexEnvi (GL_TEXTURE_ENV, GL_SRC0_RGB, src0RGB);
	glTexEnvi (GL_TEXTURE_ENV, GL_SRC1_RGB, src1RGB);
	glTexEnvi (GL_TEXTURE_ENV, GL_COMBINE_ALPHA, combineAlpha);
	glTexEnvi (GL_TEXTURE_ENV, GL_SRC0_ALPHA, src0Alpha);
}

#pragma mark -
#pragma mark Brightness

void brightnessFull (float t)	// t [0..2]
{
	GLFXPushState ();
	brightness (flipquad, t);
	GLFXPopState ();
}

void brightness (V2fT2f *quad, float t)	// t [0..2]
{
	// One pass using one unit:
	// brightness < 1.0 biases towards black
	// brightness > 1.0 biases towards white
	//
	// Note: this additive definition of brightness is
	// different than what matrix-based adjustment produces,
	// where the brightness factor is a scalar multiply.
	//
	// A +/-1 bias will produce the full range from black to white,
	// whereas the scalar multiply can never reach full white.
	
	glVertexPointer  (2, GL_FLOAT, sizeof(V2fT2f), &quad[0].x);
	glTexCoordPointer(2, GL_FLOAT, sizeof(V2fT2f), &quad[0].s);
	glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_COMBINE);
	if (t > 1.0f)
	{
		glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_RGB,      GL_ADD);
		glColor4f(t-1, t-1, t-1, t-1);
	}
	else
	{
		glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_RGB,      GL_SUBTRACT);
		glColor4f(1-t, 1-t, 1-t, 1-t);
	}
	glTexEnvi(GL_TEXTURE_ENV, GL_SRC0_RGB,         GL_TEXTURE);
	glTexEnvi(GL_TEXTURE_ENV, GL_SRC1_RGB,         GL_PRIMARY_COLOR);
	glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_ALPHA,    GL_REPLACE);
	glTexEnvi(GL_TEXTURE_ENV, GL_SRC0_ALPHA,       GL_TEXTURE);
	
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}


#pragma mark -
#pragma mark Contrast

void contrastFull (float t)	// t [0..2]
{
	contrast (flipquad, t);
}

void contrast (V2fT2f *quad, float t)	// t [0..2]
{
	GLfloat h = t*0.5f;
	
	// One pass using two units:
	// contrast < 1.0 interpolates towards grey
	// contrast > 1.0 extrapolates away from grey
	//
	// Here, the general extrapolation 2*(Src*t + Dst*(0.5-t))
	// can be simplified, because Dst is a constant (grey).
	// That results in: 2*(Src*t + 0.25 - 0.5*t)
	//
	// Unit0 calculates Src*t
	// Unit1 adds 0.25 - 0.5*t
	// Since 0.5*t will be in [0..0.5], it can be biased up and the addition done in signed space.
	
	glVertexPointer  (2, GL_FLOAT, sizeof(V2fT2f), &quad[0].x);
	glTexCoordPointer(2, GL_FLOAT, sizeof(V2fT2f), &quad[0].s);
	glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_COMBINE);
	glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_RGB,      GL_MODULATE);
	glTexEnvi(GL_TEXTURE_ENV, GL_SRC0_RGB,         GL_TEXTURE);
	glTexEnvi(GL_TEXTURE_ENV, GL_SRC1_RGB,         GL_PRIMARY_COLOR);
	glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_ALPHA,    GL_REPLACE);
	glTexEnvi(GL_TEXTURE_ENV, GL_SRC0_ALPHA,       GL_TEXTURE);
	
	glActiveTexture(GL_TEXTURE1);
//	glEnable(GL_TEXTURE_2D);
	glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_COMBINE);
	glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_RGB,      GL_ADD_SIGNED);
	glTexEnvi(GL_TEXTURE_ENV, GL_SRC0_RGB,         GL_PREVIOUS);
	glTexEnvi(GL_TEXTURE_ENV, GL_SRC1_RGB,         GL_PRIMARY_COLOR);
	glTexEnvi(GL_TEXTURE_ENV, GL_OPERAND1_RGB,     GL_SRC_ALPHA);
	glTexEnvi(GL_TEXTURE_ENV, GL_RGB_SCALE,        2);
	glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_ALPHA,    GL_REPLACE);
	glTexEnvi(GL_TEXTURE_ENV, GL_SRC0_ALPHA,       GL_PREVIOUS);
	
	glColor4f(h, h, h, 0.75 - 0.5 * h);	// 2x extrapolation
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	
	// Restore state
//	glDisable(GL_TEXTURE_2D);
	glTexEnvi(GL_TEXTURE_ENV, GL_OPERAND1_RGB,     GL_SRC_COLOR);
	glTexEnvi(GL_TEXTURE_ENV, GL_RGB_SCALE,        1);
	glActiveTexture(GL_TEXTURE0);
}


#pragma mark -
#pragma mark Grayscale

void greyscaleFull (float t)	// t = 1 for standard perceptual weighting
{
	greyscale (flipquad, t);
}

void greyscale (V2fT2f *quad, float t)	// t = 1 for standard perceptual weighting
{
	GLfloat lerp[4] = { 1.0, 1.0, 1.0, 0.5 };
	GLfloat avrg[4] = { .667, .667, .667, 0.5 };	// average
	GLfloat prcp[4] = { .646, .794, .557, 0.5 };	// perceptual NTSC
	GLfloat dot3[4] = { prcp[0]*t+avrg[0]*(1-t), prcp[1]*t+avrg[1]*(1-t), prcp[2]*t+avrg[2]*(1-t), 0.5 };
	
	// One pass using two units:
	// Unit 0 scales and biases into [0.5..1.0]
	// Unit 1 dot products with perceptual weights
	
	glVertexPointer  (2, GL_FLOAT, sizeof(V2fT2f), &quad[0].x);
	glTexCoordPointer(2, GL_FLOAT, sizeof(V2fT2f), &quad[0].s);
	glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_COMBINE);
	glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_RGB,      GL_INTERPOLATE);
	glTexEnvi(GL_TEXTURE_ENV, GL_SRC0_RGB,         GL_TEXTURE);
	glTexEnvi(GL_TEXTURE_ENV, GL_SRC1_RGB,         GL_CONSTANT);
	glTexEnvi(GL_TEXTURE_ENV, GL_SRC2_RGB,         GL_CONSTANT);
	glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_ALPHA,    GL_REPLACE);
	glTexEnvi(GL_TEXTURE_ENV, GL_SRC0_ALPHA,       GL_TEXTURE);
	glTexEnvfv(GL_TEXTURE_ENV,GL_TEXTURE_ENV_COLOR, lerp);
	
	// Note: we prefer to dot product with primary color, because
	// the constant color is stored in limited precision on MBX
	glActiveTexture(GL_TEXTURE1);
//	glEnable(GL_TEXTURE_2D);
	glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_COMBINE);
	glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_RGB,      GL_DOT3_RGB);
	glTexEnvi(GL_TEXTURE_ENV, GL_SRC0_RGB,         GL_PREVIOUS);
	glTexEnvi(GL_TEXTURE_ENV, GL_SRC1_RGB,         GL_PRIMARY_COLOR);
	glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_ALPHA,    GL_REPLACE);
	glTexEnvi(GL_TEXTURE_ENV, GL_SRC0_ALPHA,       GL_PREVIOUS);
	
	glColor4f(dot3[0], dot3[1], dot3[2], dot3[3]);
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	
	// Restore state
//	glDisable(GL_TEXTURE_2D);
	glActiveTexture(GL_TEXTURE0);
}

#pragma mark -
#pragma mark Hue

// Matrix Utilities for Hue rotation
static void matrixmult(float a[4][4], float b[4][4], float c[4][4])
{
	int x, y;
	float temp[4][4];
	
	for(y=0; y<4; y++)
		for(x=0; x<4; x++)
			temp[y][x] = b[y][0] * a[0][x] + b[y][1] * a[1][x] + b[y][2] * a[2][x] + b[y][3] * a[3][x];
	for(y=0; y<4; y++)
		for(x=0; x<4; x++)
			c[y][x] = temp[y][x];
}

static void xrotatemat(float mat[4][4], float rs, float rc)
{
	mat[0][0] = 1.0;
	mat[0][1] = 0.0;
	mat[0][2] = 0.0;
	mat[0][3] = 0.0;
	
	mat[1][0] = 0.0;
	mat[1][1] = rc;
	mat[1][2] = rs;
	mat[1][3] = 0.0;
	
	mat[2][0] = 0.0;
	mat[2][1] = -rs;
	mat[2][2] = rc;
	mat[2][3] = 0.0;
	
	mat[3][0] = 0.0;
	mat[3][1] = 0.0;
	mat[3][2] = 0.0;
	mat[3][3] = 1.0;
}

static void yrotatemat(float mat[4][4], float rs, float rc)
{
	mat[0][0] = rc;
	mat[0][1] = 0.0;
	mat[0][2] = -rs;
	mat[0][3] = 0.0;
	
	mat[1][0] = 0.0;
	mat[1][1] = 1.0;
	mat[1][2] = 0.0;
	mat[1][3] = 0.0;
	
	mat[2][0] = rs;
	mat[2][1] = 0.0;
	mat[2][2] = rc;
	mat[2][3] = 0.0;
	
	mat[3][0] = 0.0;
	mat[3][1] = 0.0;
	mat[3][2] = 0.0;
	mat[3][3] = 1.0;
}

static void zrotatemat(float mat[4][4], float rs, float rc)
{
	mat[0][0] = rc;
	mat[0][1] = rs;
	mat[0][2] = 0.0;
	mat[0][3] = 0.0;
	
	mat[1][0] = -rs;
	mat[1][1] = rc;
	mat[1][2] = 0.0;
	mat[1][3] = 0.0;
	
	mat[2][0] = 0.0;
	mat[2][1] = 0.0;
	mat[2][2] = 1.0;
	mat[2][3] = 0.0;
	
	mat[3][0] = 0.0;
	mat[3][1] = 0.0;
	mat[3][2] = 0.0;
	mat[3][3] = 1.0;
}

static void huematrix(GLfloat mat[4][4], float angle)
{
	float mag, rot[4][4];
	float xrs, xrc;
	float yrs, yrc;
	float zrs, zrc;
	
	// Rotate the grey vector into positive Z
	mag = sqrt(2.0);
	xrs = 1.0/mag;
	xrc = 1.0/mag;
	xrotatemat(mat, xrs, xrc);
	mag = sqrt(3.0);
	yrs = -1.0/mag;
	yrc = sqrt(2.0)/mag;
	yrotatemat(rot, yrs, yrc);
	matrixmult(rot, mat, mat);
	
	// Rotate the hue
	zrs = sin(angle);
	zrc = cos(angle);
	zrotatemat(rot, zrs, zrc);
	matrixmult(rot, mat, mat);
	
	// Rotate the grey vector back into place
	yrotatemat(rot, -yrs, yrc);
	matrixmult(rot,  mat, mat);
	xrotatemat(rot, -xrs, xrc);
	matrixmult(rot,  mat, mat);
}

void hueFull (float t)	// t [0..2] == [-180..180] degrees
{
	hue (flipquad, t);
}

void hue (V2fT2f *quad, float t)	// t [0..2] == [-180..180] degrees
{
	GLfloat mat[4][4];
	GLfloat lerp[4] = { 1.0, 1.0, 1.0, 0.5 };
	
	// Color matrix rotation can be expressed as three dot products
	// Each DOT3 needs inputs prescaled to [0.5..1.0]
	
	// Construct 3x3 matrix
	huematrix(mat, (t-1.0)*M_PI);
	
	// Prescale matrix weights
	mat[0][0] *= 0.5; mat[0][0] += 0.5;
	mat[0][1] *= 0.5; mat[0][1] += 0.5;
	mat[0][2] *= 0.5; mat[0][2] += 0.5;
	mat[0][3] = 1.0;
	
	mat[1][0] *= 0.5; mat[1][0] += 0.5;
	mat[1][1] *= 0.5; mat[1][1] += 0.5;
	mat[1][2] *= 0.5; mat[1][2] += 0.5;
	mat[1][3] = 1.0;
	
	mat[2][0] *= 0.5; mat[2][0] += 0.5;
	mat[2][1] *= 0.5; mat[2][1] += 0.5;
	mat[2][2] *= 0.5; mat[2][2] += 0.5;
	mat[2][3] = 1.0;
	
	glVertexPointer  (2, GL_FLOAT, sizeof(V2fT2f), &quad[0].x);
	glTexCoordPointer(2, GL_FLOAT, sizeof(V2fT2f), &quad[0].s);
	glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_COMBINE);
	glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_RGB,      GL_INTERPOLATE);
	glTexEnvi(GL_TEXTURE_ENV, GL_SRC0_RGB,         GL_TEXTURE);
	glTexEnvi(GL_TEXTURE_ENV, GL_SRC1_RGB,         GL_CONSTANT);
	glTexEnvi(GL_TEXTURE_ENV, GL_SRC2_RGB,         GL_CONSTANT);
	glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_ALPHA,    GL_REPLACE);
	glTexEnvi(GL_TEXTURE_ENV, GL_SRC0_ALPHA,       GL_TEXTURE);
	glTexEnvfv(GL_TEXTURE_ENV,GL_TEXTURE_ENV_COLOR, lerp);
	
	// Note: we prefer to dot product with primary color, because
	// the constant color is stored in limited precision on MBX
	glActiveTexture(GL_TEXTURE1);
//	glEnable(GL_TEXTURE_2D);
	glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_COMBINE);
	glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_RGB,      GL_DOT3_RGB);
	glTexEnvi(GL_TEXTURE_ENV, GL_SRC0_RGB,         GL_PREVIOUS);
	glTexEnvi(GL_TEXTURE_ENV, GL_SRC1_RGB,         GL_PRIMARY_COLOR);
	glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_ALPHA,    GL_REPLACE);
	glTexEnvi(GL_TEXTURE_ENV, GL_SRC0_ALPHA,       GL_PREVIOUS);
	
	// Red channel
	glColorMask(1,0,0,0);
	glColor4f(mat[0][0], mat[0][1], mat[0][2], mat[0][3]);
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	
	// Green channel
	glColorMask(0,1,0,0);
	glColor4f(mat[1][0], mat[1][1], mat[1][2], mat[1][3]);
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	
	// Blue channel
	glColorMask(0,0,1,0);
	glColor4f(mat[2][0], mat[2][1], mat[2][2], mat[2][3]);
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	
	// Restore state
//	glDisable(GL_TEXTURE_2D);
	glActiveTexture(GL_TEXTURE0);
	glColorMask(1,1,1,1);
}

