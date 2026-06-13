float sdEllipsoid( in vec3 p, in vec3 r ) {
    float k0 = length(p/r);
    float k1 = length(p/(r*r));
    return k0*(k0-1.0)/k1;
}

//------------------------------------------------------------------

vec2 map( in vec3 sight ) {

    // Of the object
    vec3 position = vec3( 0.0, 0.0, 0.0 );

    // The xyz component radius values of the ellipsoid
    vec3 radius = vec3( 1.5, 0.1, 1.0 );

    // Define position in relation to the camera
    position = sight - position;

    // Bend the ellipsoid on the z axis
    float bend = 0.2;
    float c = cos( position.z * bend );
    float s = sin( position.z * bend );
    mat2  m = mat2( c, - s, s, c );
    vec3  q = vec3( m * position.xy, position.z );

   	// Bend the ellipsoid on the x axis
    bend = - 0.1;
    c = cos( q.x * bend );
    s = sin( q.x * bend );
    m = mat2( c, - s, s, c );
    q = vec3( m * q.xy, q.z );

    vec3 worldPosition = q;

    float sdf = sdEllipsoid( worldPosition, radius );
    vec2 res = vec2( sdf, 0.0 );

    return res;

}

vec2 castRay( in vec3 ro, in vec3 rd ) {

    // Near / Far Clipping Plane
    float tmin = 1.0;
    float tmax = 50.0;
    
    float t = tmin;
    float m = - 1.0;
    // TODO: Why does it need so many iterations
    // to march correctly?
    for( int i = 0; i < 128; i++ ) {

	    float precis = 0.0004 * t;
	    vec2 res = map( ro + rd * t );

        // Means no intersection
        // and no possibility of checking again
        // so stop the Ray Marching
        if( res.x < precis || t > tmax ) break;

        t += res.x;
	    m = res.y; // Identify which shape was intersected via a float

    }

    if( t > tmax ) m =- 1.0;
    return vec2( t, m );
}

vec3 render( in vec3 ro, in vec3 rd ) {

    vec3 col = vec3( 0.85 );
    vec2 res = castRay( ro,rd );

    float t = res.x;
	float m = res.y;

    // Ray intersected object
    if( m >= 0.0 ) {
        // normalize t and flip it
		float tn = 1.0 - t / 24.5;
        vec3 white = vec3( 1.0, 1.0, 0.75 );
        vec3 red = vec3( 1.0, 0.0, 0.15 );
		col = mix( red, white, pow( tn, 2.0 ) );
    }

	return vec3( clamp( col, 0.0, 1.0 ) );
}

mat3 setCamera( in vec3 ro, in vec3 ta, float cr ) {

    vec3 cw = normalize( ta - ro );
	vec3 cp = vec3( sin( cr ), cos( cr ), 0.0 );
	vec3 cu = normalize( cross( cw, cp ) );
	vec3 cv = normalize( cross( cu, cw ) );

    return mat3( cu, cv, cw );

}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {

    vec2 mo = iMouse.xy / iResolution.xy;
	float time = iTime;

    vec2 p = ( - iResolution.xy + 2.0 * fragCoord ) / iResolution.y;

	// Camera Position
    // vec3 ro = vec3( 10.0 * cos( mo.x * 3.14 ), 10.0 * mo.y - 5.0, 10.0 * sin( mo.x * 3.14 ) );
    vec3 ro = vec3( 10.0 * cos( time ), 10.0 * sin( time * 2.0 ), 10.0 * sin( time ) );
    // Camera Look At Vector
    vec3 ta = vec3( 0.0, 0.0, 0.0 );
    // camera-to-world transformation
    mat3 ca = setCamera( ro, ta, 0.0 );
    // ray direction
    // TODO: Don't understand the z-component `8.0`
    // But I think it has soemthing to do with
    // the zoom of the camera.
    vec3 rd = ca * normalize( vec3( p.xy, 8.0 ) );

    // render	
    vec3 col = render( ro, rd );
    
    fragColor = vec4( col, 1.0 );

}
