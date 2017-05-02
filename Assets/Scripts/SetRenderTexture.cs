using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SetRenderTexture : MonoBehaviour {
	public string textureName = "_Heightmap";
	public Camera cam;
	// Use this for initialization
	void Start () {
		
	}
	
	// Update is called once per frame
	void Update () {
		GetComponent<MeshRenderer> ().material.SetTexture(textureName,cam.targetTexture);
	}
}
