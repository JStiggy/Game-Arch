using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;

public class DepthIntersectionCamera : MonoBehaviour {
	public int resolution = 128;
	public Material depthMat;
	public bool swapRT = true;
	private RenderTexture swap;
	private Camera cam;
	// Use this for initialization
	void OnEnable () {
		cam = GetComponent<Camera> ();
		SwapRenderTexture (MakeRenderTexture ());
		if(swapRT){
			swap = MakeRenderTexture ();
		}

	}
	
	// Update is called once per frame
	void LateUpdate () {
		if(swapRT){
			RenderTexture temp = swap;
			swap = cam.targetTexture;
			cam.targetTexture = temp;
			depthMat.SetTexture ("_Previous", swap);
		}
	}
	void OnRenderImage(RenderTexture src, RenderTexture dest) {
		Graphics.Blit(src, dest, depthMat);
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
		RenderTexture rt = new RenderTexture (xPixels, yPixels, 24, RenderTextureFormat.RFloat, RenderTextureReadWrite.Linear);
		rt.wrapMode = TextureWrapMode.Clamp;
		rt.filterMode = FilterMode.Trilinear;
		rt.enableRandomWrite = true;
		rt.Create ();
		//Zero out buffer
		Graphics.SetRenderTarget (rt.colorBuffer, rt.depthBuffer);
		GL.Clear (true, true, Color.black);

		return rt;
	}
		
	void SwapRenderTexture(RenderTexture swapIn){
		if(cam.targetTexture != null){
			cam.targetTexture.Release ();
		}
		cam.targetTexture = swapIn;
	}
	void OnDisable(){
		SwapRenderTexture (null);
		if(swapRT){
			swap.Release ();
		}
	}

}
