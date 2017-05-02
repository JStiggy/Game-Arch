using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SwapPlane : MonoBehaviour {

	public GameObject[] planes;
	int index = 0;
	// Use this for initialization
	void Awake () {
		for(int i = 0; i < planes.Length; i++){
			planes[i].SetActive(false);
		}
		planes[0].SetActive(true);
	}
	
	// Update is called once per frame
	void Update () {
		if(Input.GetKeyDown(KeyCode.Space)){
			planes[index].SetActive(false);
			index++;
			if(index >= planes.Length){
				index = 0;
			}
			planes[index].SetActive(true);
		}
	}
}
