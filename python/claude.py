import sys

import boto3
from botocore.exceptions import ClientError

client = boto3.client("bedrock-runtime", region_name="us-east-1")
model_id = "anthropic.claude-3-haiku-20240307-v1:0"

PROMPTS = {
    "enhance_annotations": """Human: Enhance the function parameters by updating or adding python3 type annotations

for
    def fetch_smalltable_rows( table_handle, keys,
        require_all_keys: bool = False,
    ):

a version with annotations might look like

    def fetch_smalltable_rows(
        table_handle: smalltable.Table,
        keys: Sequence[bytes | str],
        require_all_keys: bool = False,
    ) -> Mapping[bytes, tuple[str, ...]]:


    Use the correct type by understand the function body. Do not use "Any" if you can derive it from the function body.
    ONLY output the parameters comma-separated, without function name and parenthese
    """,
    "enhance_func_docstring": """Human: Write a google style docstring for a given function. Here is an example
    for

    def fetch_smalltable_rows(
        table_handle: smalltable.Table,
        keys: Sequence[bytes | str],
        require_all_keys: bool = False,
    ) -> Mapping[bytes, tuple[str, ...]]:

    how it can look like

        \"\"\"Fetch rows from a Smalltable.

        Retrieves rows pertaining to the given keys from the Table instance
        represented by table_handle.  String keys will be UTF-8 encoded.

        Args:
            table_handle: An open smalltable.Table instance.
            keys: A sequence of strings representing the key of each table
              row to fetch.  String keys will be UTF-8 encoded.
            require_all_keys: If True only rows with values set for all keys will be
              returned.

        Returns:
            A dict mapping keys to the corresponding table row data
            fetched. Each row is represented as a tuple of strings. For
            example:

            {b'Serak': ('Rigel VII', 'Preparer'),
             b'Zim': ('Irk', 'Invader'),
             b'Lrrr': ('Omicron Persei 8', 'Emperor')}

            Returned keys are always bytes.  If a key from the keys argument is
            missing from the dictionary, then that row was not found in the
            table (and require_all_keys must have been False).

        Raises:
            IOError: An error occurred accessing the smalltable.

        Examples:
            >>> my_table = fetch_smalltable_rows(handle, ["id", "user"], True)
        \"\"\"

    NEVER write anything else besides the docstring block. ONLY generate the docstring,
    It should include Args, Returns, Raise, Yield, Attributes if necessary. First line must be in imperative mood. Do NOT output anything else after the docstring.
    Update and correct the pre-existing docstring, parametern names or types might have changed. Wrap everything to 88 chars.
    NEVER write back the initial code, JUST the docstring itself.
    """,
    "enhance_class_docstring": """Human: Write a google style docstring for a given class. Here is an example
    for

    class ExampleClass(object):


    this is how it can look like
    \"\"\"The summary line for a class docstring should fit on one line.

    If the class has public attributes, they may be documented here
    in an ``Attributes`` section and follow the same formatting as a
    function's ``Args`` section. Alternatively, attributes may be documented
    inline with the attribute's declaration (see __init__ method below).

    Properties created with the ``@property`` decorator should be documented
    in the property's getter method.

    Attributes:
        attr1 (str): Description of `attr1`.
        attr2 (:obj:`int`, optional): Description of `attr2`.

    \"\"\"

    NEVER write anything else besides the docstring block. ONLY generate the docstring,
    It should include Args, Returns, Raise, Yield, Attributes if necessary. First line must be in imperative mood. Do NOT output anything else after the docstring.
    Update and correct the pre-existing docstring, parametern names or types might have changed. Wrap everything to 88 chars.
    NEVER write back the initial code, JUST the docstring itself.
    """,
}


def generate_llm_response(prompt: str, data: str):
    """Generate a response from a large language model (LLM).

    Args:
        prompt (str): The prompt to be used to generate the LLM response.
        data (str): Additional data to be included in the prompt.

    Returns:
        str: The generated response from the LLM.

    Raises:
        ClientError: An error occurred while invoking the LLM model.
        Exception: An unexpected error occurred.
    """
    user_message = prompt
    user_message += """
    Here is the task:
    <task >
    """
    user_message += data
    user_message += """
    < / task >

    Assistant:
    """
    conversation = [
        {
            "role": "user",
            "content": [{"text": user_message}],
        }
    ]

    try:
        # Send the message to the model, using a basic inference configuration.
        response = client.converse(
            # modelId="anthropic.claude-v2",
            modelId="anthropic.claude-3-haiku-20240307-v1:0",
            # modelId="anthropic.claude-3-sonnet-20240229-v1:0",
            messages=conversation,
            inferenceConfig={
                "maxTokens": 2048,
                "stopSequences": ["\n\nHuman:"],
                "temperature": 0,
                "topP": 1,
            },
            additionalModelRequestFields={"top_k": 250},
        )

        response_text = response["output"]["message"]["content"][0]["text"]
        return response_text

    except (ClientError, Exception) as e:
        print(f"ERROR: Can't invoke '{model_id}'. Reason: {e}")
        exit(1)


if __name__ == "__main__":
    prompt_name = sys.argv[1]
    input_text = sys.stdin.read()

    output_text = generate_llm_response(PROMPTS[prompt_name], input_text)

    print(output_text)
