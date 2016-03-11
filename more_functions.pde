// Global named render objects

ArrayList<RenderObj> namedRenderObjs = new ArrayList<RenderObj>();
ArrayList<String> renderObjNames = new ArrayList<String>();
//RenderObj[] namedRenderObjs = new RenderObj[maxNamedPrim];
//String[] renderObjNames = new String[maxNamedPrim];


void addNamedObject( RenderObj renderObj, String name ) {

  if( renderObj.getPrimitiveType() == sphereType ) {
    Sphere sphere = new Sphere();
    sphere.cloneData((Sphere) renderObj);
//  println("Radius is "+sphere.radius);
    namedRenderObjs.add(sphere);        
  } 
  else if( renderObj.getPrimitiveType() == triangleType ) {
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

/**< combine: Get the bounding box from two bounding boxes */
Box combineBoxes( Box leftBox, Box rightBox) {

  Box b = new Box();
  if (leftBox.minPt.x < rightBox.minPt.x) {
    b.minPt.x = leftBox.minPt.x;
  } 
  else {
    b.minPt.x = rightBox.minPt.x;
  }
  
  if (leftBox.minPt.y < rightBox.minPt.y) {
    b.minPt.y = leftBox.minPt.y;
  } 
  else {
    b.minPt.y = rightBox.minPt.y;
  }
  
  if (leftBox.minPt.z < rightBox.minPt.z) {
    b.minPt.z = leftBox.minPt.z;
  } 
  else {
    b.minPt.z = rightBox.minPt.z;
  }

  if (leftBox.maxPt.x > rightBox.maxPt.x) {
    b.maxPt.x = leftBox.maxPt.x;
  } 
  else {
    b.maxPt.x = rightBox.maxPt.x;
  }
  
  if (leftBox.maxPt.y > rightBox.maxPt.y) {
    b.maxPt.y = leftBox.maxPt.y;
  }
  else {
    b.maxPt.y = rightBox.maxPt.y;
  }
  
  if (leftBox.maxPt.z > rightBox.maxPt.z) {
    b.maxPt.z = leftBox.maxPt.z;
  } 
  else {
    b.maxPt.z = rightBox.maxPt.z;
  }
  
  return b;
}