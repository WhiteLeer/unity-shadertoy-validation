/*
    Copyright (c) 2021 al-ro

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
*/

#define PI 3.14159
#define FOUR_PI 4.0 * PI
#define GAMMA 2.2
#define INV_GAMMA (1.0/GAMMA)

// Minimum dot product value
const float minDot = 1e-3;

// Clamped dot product
float dot_c(vec3 a, vec3 b){
	return max(dot(a, b), minDot);
}

vec3 gamma(vec3 col){
	return pow(col, vec3(INV_GAMMA));
}

vec3 inv_gamma(vec3 col){
	return pow(col, vec3(GAMMA));
}

float saturate(float x){
	return clamp(x, 0.0, 1.0);
}

