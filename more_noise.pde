import java.util.Random;
class WorleyNoise{
    
  Random random;

  WorleyNoise(){
    random = new Random();  
  }
  
  //Implementing the worley noise algorithm
  float[] getNoise( float x, float y, float z){
    // Referred to https://aftbit.com/cell-noise-2/ for a bit
    float[] distance = new float[3]; // dist1, dist2, index
  
    //Determine which cube the evaluation point is in
    
    //The algorithm divides space into a regular grid of cubes whose locations are at integer locations. 
    int intX = floor(x);
    int intY = floor(y);
    int intZ = floor(z);
    
    // Get distances inside the central voxel 
    ArrayList<Float> distances = new ArrayList<Float>(); 
    ArrayList<Integer> indices = new ArrayList<Integer>();     
    ArrayList<PVector> points = new ArrayList<PVector>();      
    
    for( int i = -1; i < 2; ++i ) {
      for( int j = -1; j < 2; ++j ) {
        for( int k = -1; k < 2; ++k ) { 
          ArrayList<Float> dists = new ArrayList<Float>();          
          ArrayList<Integer> inds = new ArrayList<Integer>();
          ArrayList<PVector> pts = new ArrayList<PVector>();          
          dists = getCubeDists( intX + i, intY + j, intZ + k, x, y, z, inds, pts);
                                  
          // Store the dists, indices and pts                   
          for(int a = 0; a < dists.size(); a++ ) {
            distances.add( dists.get(a));
            indices.add(inds.get(a));
            points.add(pts.get(a));
          }                        
        }
      }
    }
    
    // get the closest
    float minDist = 9999; 
    int minIndex = 0; 
    PVector minPt = new PVector();
    float minDistTwo = 9999; // Second closest
    float dist; 
    for(int i = 0; i < distances.size(); i++) {
        dist = distances.get(i);  
        if(dist < minDist) { 
            minDist = dist;  
            minIndex = indices.get(i); 
            minPt = points.get(i); 
        }
    }
    
    // Check the next closest
    for(int i = 0; i < distances.size(); i++) {
        dist = distances.get(i);
        if( dist > minDist && dist < minDistTwo ) {
            minDistTwo = dist; 
        }
    }    
  
    // Store the first and second distances
    distance[0] = sqrt(minDist); // Squared distance is returned by the other function
    distance[1] = sqrt(minDistTwo);
    distance[2] = minIndex;
    
    return distance;

  }
  
  //Setting the seed for the random number generator. Creating a 16 bit hash
  void seed(int x,int y,int z){
    long seed = x*65633 + y*65413 + z;
    random.setSeed(seed);
  }
  
  // Get feature point distances  
  ArrayList<Float> getCubeDists(int intX, int intY, int intZ, float x, float y, float z, ArrayList<Integer> inds, ArrayList<PVector> pts ) {
    
    ArrayList<Float> dists = new ArrayList<Float>();
    int numPoints;
    // The cube values are used to seed the random number generator 
    seed(intX, intY, intZ);
    // The number of points is calculated using linear interpolation and the random number
    numPoints = floor(lerp(2, 12, random.nextFloat())); 
 
    // The random number is then used to calculate the coordinates of the points 
    for(int i = 0; i < numPoints; i++) {
        float[] featPoint = new float[3];
        featPoint[0] = intX + random.nextFloat();
        featPoint[1] = intY + random.nextFloat();
        featPoint[2] = intZ + random.nextFloat();
        
        // find the distances.
        float dx = featPoint[0]-x; float dy = featPoint[1]-y; float dz = featPoint[2]-z;
        float dist = dx*dx + dy*dy + dz*dz;
        
        dists.add(dist);
        inds.add(i);
        pts.add(new PVector(featPoint[0], featPoint[1], featPoint[2]));
    }

    return dists;
  }
}


 PVector stoneColor(float[] D, float x, float y, float z ) {

   int index = (int)D[2];
   // The grey color in the gap. Cement
   PVector gapColor = new PVector(0.70, 0.70, 0.70);
   // Tile color
   PVector tileColor = new PVector(0.62, 0.38, 0.15);
   PVector finalColor = new PVector();
   float gapThreshold = 0.03;  // For the cement gap
   float noise = D[1] - D[0];  // Difference between the closest and 2nd closest 
   if( noise < gapThreshold && noise > -1*gapThreshold ) {
       float f = 50.0;
       float n = noise_3d(f*x, f*y, f*z)*0.5;
       n = 0.8*n + 0.7; 
       finalColor.x = gapColor.x*n;
       finalColor.y = gapColor.y*n;
       finalColor.z = gapColor.z*n;     
       return finalColor;      
   }
   else {
       Random random = new Random(index);
       float f = 40.0;
       float n = noise_3d(f*x, f*y, f*z)*0.5 + 0.4;
       //Applying the tile color and adding some noise to it
       finalColor.x = tileColor.x*random.nextFloat() + tileColor.x*n*0.15;
       finalColor.y = tileColor.y*random.nextFloat() + tileColor.y*n*0.15;
       finalColor.z = tileColor.z*random.nextFloat() + tileColor.z*n*0.15;     
       return finalColor;
   }
} 