using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ToggleHelp : MonoBehaviour {

	public GameObject toggleText;
	// Use this for initialization
	void Start () {
		
	}
	
	// Update is called once per frame
	void Update () {
		if(Input.GetKeyDown(KeyCode.H)){
			toggleText.SetActive(!toggleText.activeSelf);
		}
	}
}
