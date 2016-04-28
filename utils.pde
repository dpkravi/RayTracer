 
public float distance(PVector a, PVector b){
  return sqrt(sq(a.x-b.x) + sq(a.y-b.y) + sq(a.z-b.z));
}
  
//Create a vector from pt1 to pt2 
PVector createVec(PVector pt1, PVector pt2){
    return new PVector(pt2.x-pt1.x, pt2.y-pt1.y, pt2.z-pt1.z);
}  

float smallest(float a, float b){
  if(a > 0 && a < b){
    return a;
  }
  else if(b > 0 && b < a){
    return b;
  }
  return -1;
}