using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FireObject : MonoBehaviour {

	public GameObject[] prefabs;
	public Material[] mats;
	public float fireSpeed = 4f;
	// Use this for initialization
	void Start () {
		
	}
	
	// Update is called once per frame
	void Update () {
		if(Input.GetMouseButtonDown(0)){
			//Instantiate and throw random object given a random material and size
			GameObject go = GameObject.Instantiate(prefabs[Random.Range(0,prefabs.Length)], transform.position + transform.forward * 2f, Quaternion.identity);
			float size = Random.Range(.5f, 1.25f);
			go.transform.localScale = Vector3.one * size;
			Rigidbody rb = go.GetComponent<Rigidbody>();
			//Set mass based on volume
			rb.mass = size * size;
			rb.AddTorque(Random.insideUnitSphere,ForceMode.Impulse); //Give it some spin to make it look nicer
			rb.velocity = transform.forward * fireSpeed; 
			//Assign mat
			go.GetComponent<Renderer>().material = mats[Random.Range(0,mats.Length)];
		}

		if(Input.GetKeyDown(KeyCode.Backspace)|| Input.GetKeyDown(KeyCode.Delete)){
			//Delete all thrown objects with tag
			var objs = GameObject.FindGameObjectsWithTag("Throwable");
			for (int i = 0, objsLength = objs.Length; i < objsLength; i++) {
				Destroy(objs[i]);
			}
		}
	}
}
