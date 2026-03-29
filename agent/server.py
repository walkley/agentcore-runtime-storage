from bedrock_agentcore.runtime import BedrockAgentCoreApp

app = BedrockAgentCoreApp()

@app.entrypoint
def handle_request(payload):
    prompt = payload.get("prompt", "")
    return {"response": f"Received: {prompt}"}

if __name__ == "__main__":
    app.run()
