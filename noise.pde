// Classic Perlin noise, 3D version

float noise_3d(float x, float y, float z) {
  
  // make sure we've initilized table
  if (init_flag == false) {
    initialize_table();
    init_flag = true;
  }
  
  // Find unit grid cell containing point
  int X = fastfloor(x);
  int Y = fastfloor(y);
  int Z = fastfloor(z);
  
  // Get relative xyz coordinates of point within that cell
  x = x - X;
  y = y - Y;
  z = z - Z;
  
  // Wrap the integer cells at 255 (smaller integer period can be introduced here)
  X = X & 255;
  Y = Y & 255;
  Z = Z & 255;
  
  // Calculate a set of eight hashed gradient indices
  int gi000 = perm[X+perm[Y+perm[Z]]] % 12;
  int gi001 = perm[X+perm[Y+perm[Z+1]]] % 12;
  int gi010 = perm[X+perm[Y+1+perm[Z]]] % 12;
  int gi011 = perm[X+perm[Y+1+perm[Z+1]]] % 12;
  int gi100 = perm[X+1+perm[Y+perm[Z]]] % 12;
  int gi101 = perm[X+1+perm[Y+perm[Z+1]]] % 12;
  int gi110 = perm[X+1+perm[Y+1+perm[Z]]] % 12;
  int gi111 = perm[X+1+perm[Y+1+perm[Z+1]]] % 12;
  
  // The gradients of each corner are now:
  // g000 = grad3[gi000];
  // g001 = grad3[gi001];
  // g010 = grad3[gi010];
  // g011 = grad3[gi011];
  // g100 = grad3[gi100];
  // g101 = grad3[gi101];
  // g110 = grad3[gi110];
  // g111 = grad3[gi111];
  
  // Calculate noise contributions from each of the eight corners
  double n000= dot(grad3[gi000], x, y, z);
  double n100= dot(grad3[gi100], x-1, y, z);
  double n010= dot(grad3[gi010], x, y-1, z);
  double n110= dot(grad3[gi110], x-1, y-1, z);
  double n001= dot(grad3[gi001], x, y, z-1);
  double n101= dot(grad3[gi101], x-1, y, z-1);
  double n011= dot(grad3[gi011], x, y-1, z-1);
  double n111= dot(grad3[gi111], x-1, y-1, z-1);
  
  // Compute the fade curve value for each of x, y, z
  double u = fade(x);
  double v = fade(y);
  double w = fade(z);
  
  // Interpolate along x the contributions from each of the corners
  double nx00 = mix(n000, n100, u);
  double nx01 = mix(n001, n101, u);
  double nx10 = mix(n010, n110, u);
  double nx11 = mix(n011, n111, u);
  
  // Interpolate the four results along y
  double nxy0 = mix(nx00, nx10, v);
  double nxy1 = mix(nx01, nx11, v);
  
  // Interpolate the two last results along z
  float nxyz = (float) mix(nxy0, nxy1, w);
  
  return nxyz;
}

PVector woodColor(float x, float y, float z) {

    PVector pt = new PVector(x,y,z);
    float ring = sqrt( pt.y*pt.y + pt.z*pt.z );
    float radius = sqrt(pt.x*pt.x + pt.y*pt.y + pt.z*pt.z );
    ring += (noise_3d( pt.x, pt.y, pt.z ) * radius/5);

    // To give a noisy texture to the dark ring. Adds variation to the rings
    float noiseScale = 8.0;
    float radiusVariation = noise_3d(pt.x, pt.y*noiseScale, pt.z*noiseScale)/50.0;  //Testing with these numbers to give appealing final pattern
    ring += radiusVariation;

    // Adding higher frequency noise to previous noise to produce more randomness
    noiseScale = 50.0;   
    float moreRadiusVariation = noise_3d(pt.x, pt.y*noiseScale, pt.z*noiseScale)/100.0; 
    ring += moreRadiusVariation;

    //This noise gives an overall fine grainy texture to the wood
    noiseScale = 100.0;   //Very fine grain
    float grainNoise = noise_3d(pt.x * noiseScale, pt.y * noiseScale, pt.z * noiseScale)/8.0; //Dividing by 8 to reduce intensity of the noise.


    float ringGap = 0.04*radius; //Gap between two rings
    float num = ring/ringGap;
    int numRings = floor(num);
    float blendVar = 2.0 * abs((numRings + 0.5)-num); //This gives the gradient distances to blend the colors

    //light and dark brown rings
    PVector lightRing = new PVector( 0.85, 0.68, 0.52 );
    PVector darkRing = new PVector( 0.58, 0.43, 0.32 ); 

    
    if (numRings % 2 == 0)   //Every alternate ring should be a light ring with uniform color
        return new PVector( lightRing.x + grainNoise, lightRing.y + grainNoise, lightRing.z + grainNoise );
    else   // The other alternate rings should be a dark ring which blends with the light ring based on the blendVar 
    {
      //blending the colors to make smoother transitions between the colors. 
      PVector blendedColor = blendColors(darkRing, lightRing, blendVar);
      //adding the fine grain texture
      blendedColor.add( grainNoise, grainNoise, grainNoise );
      return blendedColor;
    }
}

//blend the two colors based on the value of t. This produces gradient edges
PVector blendColors(PVector firstColor, PVector secondColor, float t){
    PVector blended = new PVector();
    blended.x = (1-t)*firstColor.x + t*secondColor.x;
    blended.y = (1-t)*firstColor.y + t*secondColor.y;
    blended.z = (1-t)*firstColor.z + t*secondColor.z;
    PVector clamped = clamp(blended);
    return clamped;
}

PVector clamp(PVector Color)
{
  Color.x = clamp(Color.x);
  Color.y = clamp(Color.y);
  Color.z = clamp(Color.z);
  return Color;
}

//Clamp values between 0 and 1
float clamp(float val)
{
  if ( val < 0 )
      val = 0;
  else if ( val > 1 )
      val = 1;
  return val;
}

PVector marbleColor(float n){
// From Computer Graphics: Theory Into Practice By Jeffrey J. McConnell

  PVector finalColor = new PVector();
  
  //These two colors will be merged for the marble
  PVector color1 = new PVector(0.2,0.2,0.0);
  PVector color2 = new PVector(0.9,0.8,0.4);
  
  // Color Difference 
  PVector colorDiff = new PVector(0,0,0);
  colorDiff.x = color2.x - color1.x;
  colorDiff.y = color2.y - color1.y;
  colorDiff.z = color2.z - color1.z;
  
  float f = sqrt( n + 1.0 )*0.7071;
  finalColor.y = color1.y + colorDiff.y*f;
  f = sqrt(f);
  finalColor.x = color1.x + colorDiff.x*f;
  finalColor.z = color1.z + colorDiff.z*f;  
 
  return finalColor;
}



float turbulence( float x, float y, float z) {
// http://http.developer.nvidia.com/GPUGems/gpugems_ch05.html
    float noise = 0;
    x+=128;
        
    //maximum pixel size
    float fmax = 300;
    float f;
        
    for(f = 1; f < fmax; f = f*2.0) {
      noise = noise + (1.0/f)*abs(noise_3d(x,y,z));
      x = x*2.0; y = y*2.0; z = z*2.0;    
    }
    return noise;
}

boolean init_flag = false;

int grad3[][] = {{1,1,0},{-1,1,0},{1,-1,0},{-1,-1,0},
{1,0,1},{-1,0,1},{1,0,-1},{-1,0,-1},
{0,1,1},{0,-1,1},{0,1,-1},{0,-1,-1}};

int p[] = {151,160,137,91,90,15,
131,13,201,95,96,53,194,233,7,225,140,36,103,30,69,142,8,99,37,240,21,10,23,
190, 6,148,247,120,234,75,0,26,197,62,94,252,219,203,117,35,11,32,57,177,33,
88,237,149,56,87,174,20,125,136,171,168, 68,175,74,165,71,134,139,48,27,166,
77,146,158,231,83,111,229,122,60,211,133,230,220,105,92,41,55,46,245,40,244,
102,143,54, 65,25,63,161, 1,216,80,73,209,76,132,187,208, 89,18,169,200,196,
135,130,116,188,159,86,164,100,109,198,173,186, 3,64,52,217,226,250,124,123,
5,202,38,147,118,126,255,82,85,212,207,206,59,227,47,16,58,17,182,189,28,42,
223,183,170,213,119,248,152, 2,44,154,163, 70,221,153,101,155,167, 43,172,9,
129,22,39,253, 19,98,108,110,79,113,224,232,178,185, 112,104,218,246,97,228,
251,34,242,193,238,210,144,12,191,179,162,241, 81,51,145,235,249,14,239,107,
49,192,214, 31,181,199,106,157,184, 84,204,176,115,121,50,45,127, 4,150,254,
138,236,205,93,222,114,67,29,24,72,243,141,128,195,78,66,215,61,156,180};

// To remove the need for index wrapping, double the permutation table length
int perm[] = new int[512];

void initialize_table() {
  for(int i=0; i<512; i++) perm[i]=p[i & 255];
}

// This method is a *lot* faster than using (int)Math.floor(x)
int fastfloor(double x) {
  return x>0 ? (int)x : (int)x-1;
}

double dot(int g[], double x, double y, double z) {
  return g[0]*x + g[1]*y + g[2]*z;
}

double mix(double a, double b, double t) {
  return (1-t)*a + t*b;
}

double fade(double t) {
  return t*t*t*(t*(t*6-15)+10);
}