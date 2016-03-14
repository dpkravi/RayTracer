// Global named render objects

ArrayList<RenderObj> namedRenderObjs = new ArrayList<RenderObj>();
ArrayList<String> renderObjNames = new ArrayList<String>();

void addNamedObject( RenderObj renderObj, String name ) {

  if( renderObj.getPrimitiveType() == sphere ) {
    Sphere sphere = new Sphere();
    sphere.cloneData((Sphere) renderObj);
//  println("Radius is "+sphere.radius);
    namedRenderObjs.add(sphere);        
  } 
  else if( renderObj.getPrimitiveType() == triangle ) {
      namedRenderObjs.add((Triangle) renderObj);      
  } 
  
  renderObjNames.add(name);

}   


int getInstanceIndex( String name ) {

  for( int i = 0; i < renderObjNames.size(); i++ ) {
      if( renderObjNames.get(i).equals(name) ) 
      { 
          return i; 
      }
  }
  return -1;   
}

PVector createVec(PVector pt1, PVector pt2){
    return new PVector(pt2.x-pt1.x, pt2.y-pt1.y, pt2.z-pt1.z);
}  