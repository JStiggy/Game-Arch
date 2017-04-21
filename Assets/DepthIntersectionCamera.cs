using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;

public class DepthIntersectionCamera : MonoBehaviour {
	public int resolution = 128;
	private Camera cam;
	// Use this for initialization
	void Start () {
		cam = GetComponent<Camera> ();
		SwapRenderTexture (MakeRenderTexture ());
	}
	
	// Update is called once per frame
	void Update () {

	}

	/// <summary>
	/// Makes the render texture.
	/// </summary>
	/// <returns>The render texture.</returns>
	/// <param name="scaleTexture">If set to <c>true</c> scale texture to non power of 2 values based on camera x and yscale (results in smaller render texture).</param>
	RenderTexture MakeRenderTexture(bool scaleTexture = false){
		int xPixels, yPixels;
		if (scaleTexture) {
			float xRatio = transform.localScale.x / transform.localScale.y;
			float xScale = transform.localScale.x;
			float yScale = transform.localScale.y;

			if (xScale > yScale) {
				xPixels = resolution;
				yPixels = (int)(1f / xRatio * resolution);
			} else { //yScale >= xScale
				xPixels = (int)(xRatio * resolution);
				yPixels = resolution;				
			}
		} else {
			xPixels = resolution;
			yPixels = resolution;
		}
		RenderTexture rt = new RenderTexture (xPixels, yPixels, 24, RenderTextureFormat.Depth, RenderTextureReadWrite.Linear);
		rt.wrapMode = TextureWrapMode.Clamp;
		rt.filterMode = FilterMode.Trilinear;
		rt.Create ();
		return rt;
	}
		
	void SwapRenderTexture(RenderTexture swapIn){
		if(cam.targetTexture != null){
			cam.targetTexture.Release ();
		}
		cam.targetTexture = swapIn;

	}
	void OnDestroy(){
		SwapRenderTexture (null);
	}

}
