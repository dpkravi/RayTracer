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
          println("Instance Index is "+i);
          return i; 
      }
  }
  return -1;   
}